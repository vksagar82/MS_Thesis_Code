import subprocess
import time
import psutil
import csv
from datetime import datetime
import os
from psutil import Process
from os import getpid
import re

# Global variables
global_successful_iterations = 0  # Added for progress tracking
global_failed_iterations = 0      # Added for progress tracking

# Base results directory
RESULTS_DIR = "MS_Thesis_test_result"
if not os.path.exists(RESULTS_DIR):
    os.makedirs(RESULTS_DIR)
    # Create a README.md file
    readme_path = os.path.join(RESULTS_DIR, "README.md")
    with open(readme_path, 'w') as f:
        f.write("# Automation Test Results\n\n")
        f.write(
            "This directory contains test results for Ansible and Salt automation tools.\n")

# Define device configurations
DEVICE_CONFIGS = {
    3: {'cisco': 1, 'arista': 1, 'juniper': 1},
    12: {'cisco': 4, 'arista': 4, 'juniper': 4},
    18: {'cisco': 6, 'arista': 6, 'juniper': 6},
    30: {'cisco': 10, 'arista': 10, 'juniper': 10}
}

# Actual device lists from inventory
DEVICE_LISTS = {
    'cisco': [
        "cisco5-65001", "cisco4-65002", "cisco8-65003",
        "cisco6-65001", "cisco5-65002", "cisco7-65003",
        "cisco7-65001", "cisco7-65002", "cisco8-65002",
        "cisco6-65002"
    ],
    'juniper': [
        "juniper1-65001", "juniper1-65002", "juniper5-65003",
        "juniper2-65001", "juniper3-65002", "juniper6-65003",
        "juniper3-65001", "juniper2-65002", "juniper8-65001",
        "juniper4-65001"
    ],
    'arista': [
        "arista9-65001", "arista11-65002", "arista1-65003",
        "arista10-65001", "arista9-65002", "arista2-65003",
        "arista11-65001", "arista10-65002", "arista3-65003",
        "arista4-65003"
    ]
}

# Global variables to track cumulative results
global_successful_devices = set()
global_failed_devices = set()


def create_tool_results_directory(tool):
    """Create nested directory structure for results"""
    base_dir = "MS_Thesis_test_result"
    tool_dir = os.path.join(base_dir, tool)

    if not os.path.exists(base_dir):
        os.makedirs(base_dir)
        print(f"Created base directory: {base_dir}")

    if not os.path.exists(tool_dir):
        os.makedirs(tool_dir)
        print(f"Created tool directory: {tool_dir}")

    return tool_dir


def get_tool_choice():
    while True:
        print("\nSelect automation tool:")
        print("1. Ansible")
        print("2. Salt")
        try:
            choice = int(input("\nSelect tool (1-2): "))
            if choice in [1, 2]:
                tools = {1: "Ansible", 2: "Salt"}
                return tools[choice]
            print("Please enter either 1 or 2")
        except ValueError:
            print("Please enter a valid number")


def get_state_name():
    while True:
        print("\nAvailable states:")
        print("1. one_change")
        print("2. four_changes")
        print("3. all_changes")
        try:
            choice = int(input("\nSelect state (1-3): "))
            if choice in [1, 2, 3]:
                states = {1: "one_change", 2: "four_changes", 3: "all_changes"}
                return states[choice]
            print("Please enter a number between 1 and 3")
        except ValueError:
            print("Please enter a valid number")


def get_device_count():
    while True:
        print("\nAvailable device configurations:")
        print("1. 3 devices (1 each of Cisco, Arista, Juniper)")
        print("2. 12 devices (4 each of Cisco, Arista, Juniper)")
        print("3. 18 devices (6 each of Cisco, Arista, Juniper)")
        print("4. All 30 devices (10 each of Cisco, Arista, Juniper)")

        try:
            choice = int(input("\nSelect configuration (1-4): "))
            device_counts = {1: 3, 2: 12, 3: 18, 4: 30}
            if choice in device_counts:
                return device_counts[choice]
            print("Please enter a number between 1 and 4")
        except ValueError:
            print("Please enter a valid number")


def get_devices_for_config(device_count):
    config = DEVICE_CONFIGS[device_count]
    selected_devices = []

    print("\nSelected devices:")
    for vendor in ['cisco', 'arista', 'juniper']:
        count = config[vendor]
        devices = DEVICE_LISTS[vendor][:count]
        selected_devices.extend(devices)
        print(f"{vendor.capitalize()}: {', '.join(devices)}")

    return selected_devices


def get_system_metrics():
    """Get CPU, memory, network, and disk metrics"""
    try:
        cpu_times = psutil.cpu_times()
        net_io = psutil.net_io_counters()
        disk_io = psutil.disk_io_counters()
        system_memory = psutil.virtual_memory()
        process_memory = psutil.Process().memory_info()

        return {
            'cpu_times': cpu_times,
            'net_io': net_io,
            'disk_io': disk_io,
            'system_memory': system_memory,
            'process_memory': process_memory
        }
    except Exception as e:
        print(f"Error getting system metrics: {e}")
        return None


def calculate_resource_usage(start_metrics, end_metrics):
    """Calculate the difference in resource usage"""
    if not (start_metrics and end_metrics):
        return 0, 0, 0, 0, 0, 0

    try:
        # CPU Usage calculation
        start_cpu = start_metrics['cpu_times']
        end_cpu = end_metrics['cpu_times']

        start_total = sum([getattr(start_cpu, field)
                          for field in start_cpu._fields])
        end_total = sum([getattr(end_cpu, field) for field in end_cpu._fields])

        start_busy = start_cpu.user + start_cpu.system
        end_busy = end_cpu.user + end_cpu.system

        if end_total - start_total > 0:
            cpu_percent = ((end_busy - start_busy) /
                           (end_total - start_total)) * 100
        else:
            cpu_percent = 0

        # Memory Usage - Updated calculation
        # Current memory usage in MB
        memory_used_mb = end_metrics['process_memory'].rss / 1024 / 1024
        # Total system memory in MB
        total_memory = end_metrics['system_memory'].total / 1024 / 1024
        memory_percent = (memory_used_mb / total_memory) * 100

        # Network I/O
        bytes_sent = end_metrics['net_io'].bytes_sent - \
            start_metrics['net_io'].bytes_sent
        bytes_recv = end_metrics['net_io'].bytes_recv - \
            start_metrics['net_io'].bytes_recv

        # Disk I/O
        disk_io_bytes = (
            (end_metrics['disk_io'].read_bytes - start_metrics['disk_io'].read_bytes) +
            (end_metrics['disk_io'].write_bytes -
             start_metrics['disk_io'].write_bytes)
        )

        return cpu_percent, memory_used_mb, memory_percent, bytes_sent, bytes_recv, disk_io_bytes

    except Exception as e:
        print(f"Error calculating resource usage: {e}")
        return 0, 0, 0, 0, 0, 0


def execute_automation_command(tool, state_name, devices):
    global global_successful_devices, global_failed_devices, global_successful_iterations, global_failed_iterations

    try:
        target_devices = ','.join(devices)
        if tool == "Salt":
            cmd = f"sudo salt -L '{target_devices}' state.apply {state_name} -t 60000"
        else:  # Ansible
            cmd = f"ansible-playbook -i hosts /etc/ansible/playbooks/{state_name}.yml --limit {target_devices}"

        print(f"\nExecuting command: {cmd}")

        process = subprocess.Popen(
            cmd,
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            bufsize=1,
            universal_newlines=True
        )

        output_lines = []
        iteration_failed_devices = set()
        iteration_successful_devices = set()
        current_device = None
        current_states = {}

        while True:
            line = process.stdout.readline()
            if not line and process.poll() is not None:
                break
            if line:
                line = line.strip()
                output_lines.append(line)

                if tool == "Salt":
                    if line.startswith("ID:"):
                        current_device = line.split("ID: ")[-1].strip()
                        current_states[current_device] = {
                            "success": 0, "failure": 0}
                    elif "Success:" in line and current_device:
                        if "True" in line:
                            current_states[current_device]["success"] += 1
                        elif "False" in line:
                            current_states[current_device]["failure"] += 1
                    elif "----------" in line and current_device:
                        if current_states[current_device]["failure"] == 0:
                            iteration_successful_devices.add(current_device)
                            global_successful_devices.add(current_device)
                            if current_device in global_failed_devices:
                                global_failed_devices.remove(current_device)
                        else:
                            iteration_failed_devices.add(current_device)
                            global_failed_devices.add(current_device)
                            if current_device in global_successful_devices:
                                global_successful_devices.remove(
                                    current_device)

        stderr_output = process.stderr.read()
        return_code = process.wait()

        # Update global iteration counters
        if len(iteration_failed_devices) == 0:
            global_successful_iterations += 1
        else:
            global_failed_iterations += 1

        return output_lines, stderr_output, return_code, len(iteration_failed_devices)

    except Exception as e:
        print(f"Error in execute_automation_command: {e}")
        return None, str(e), 1, 0


def get_output_filename(tool, state_name, device_count):
    """Generate output filename with tool-specific directory"""
    tool_dir = create_tool_results_directory(tool)
    filename = f"{state_name}_{device_count}_devices.csv"
    return os.path.join(tool_dir, filename)


def run_iterations():
    print("=== Starting 50 Iterations Each of Alternating Apply and Remove Operations (100 total) ===")

    tool = get_tool_choice()
    device_count = get_device_count()
    selected_devices = get_devices_for_config(device_count)
    base_state_name = get_state_name()

    print(f"\nSelected Configuration:")
    print(f"Tool: {tool}")
    print(f"Number of devices: {device_count}")
    print(f"Base state: {base_state_name}")
    print(f"Selected devices: {', '.join(selected_devices)}")

    apply_count = 0
    remove_count = 0
    iteration = 0

    while apply_count < 50 or remove_count < 50:
        iteration += 1

        # Clear previous progress display and show new progress
        print('\033[3A\033[J', end='')
        completion = (iteration / 100) * 100
        progress_chars = int(completion / 2)
        progress_bar = '#' * progress_chars + '.' * (50 - progress_chars)
        print(f"Progress [{progress_bar}][{completion:.1f}%]")
        print(f"Success: {global_successful_iterations}")
        print(f"Failed: {global_failed_iterations}")

        try:
            if iteration % 2 == 1 and apply_count < 50:
                operation = "apply"
                apply_count += 1
                current_count = apply_count
            elif remove_count < 50:
                operation = "remove"
                remove_count += 1
                current_count = remove_count
            else:
                operation = "apply"
                apply_count += 1
                current_count = apply_count

            state_name = f"remove_{base_state_name}" if operation == "remove" else base_state_name
            output_file = get_output_filename(tool, state_name, device_count)

            start_metrics = get_system_metrics()
            start_time = time.time()

            output, errors, return_code, failed_count = execute_automation_command(
                tool, state_name, selected_devices)

            end_metrics = get_system_metrics()
            execution_time = time.time() - start_time

            cpu_used, memory_used_mb, memory_percent, net_bytes_sent, net_bytes_recv, disk_io_bytes = calculate_resource_usage(
                start_metrics, end_metrics)

            bytes_per_second = net_bytes_sent / execution_time if execution_time > 0 else 0

            if return_code == 0:
                timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                csv_row = {
                    'Timestamp': timestamp,
                    'Tool': tool,
                    'Operation': operation,
                    'State': state_name,
                    'Number_of_Devices': device_count,
                    'Device_Names': ','.join(selected_devices),
                    'Execution_Time': f"{execution_time:.2f}",
                    'CPU_Usage': f"{cpu_used:.2f}",
                    'Memory_Usage_MB': f"{memory_used_mb:.2f}",
                    'Memory_Usage_Percent': f"{memory_percent:.2f}",
                    'Network_Bytes_Sent': str(net_bytes_sent),
                    'Network_Bytes_Received': str(net_bytes_recv),
                    'Disk_IO_Bytes': str(disk_io_bytes),
                    'Throughput': f"{bytes_per_second:.2f}",
                }

                file_exists = os.path.isfile(output_file)
                with open(output_file, 'a', newline='') as csvfile:
                    fieldnames = ['Timestamp', 'Tool', 'Operation', 'State',
                                  'Number_of_Devices', 'Device_Names', 'Execution_Time',
                                  'CPU_Usage', 'Memory_Usage_MB', 'Memory_Usage_Percent',
                                  'Network_Bytes_Sent', 'Network_Bytes_Received',
                                  'Disk_IO_Bytes', 'Throughput']
                    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

                    if not file_exists:
                        writer.writeheader()
                    writer.writerow(csv_row)

            if iteration < 100:
                time.sleep(3)

        except KeyboardInterrupt:
            print("\nIterations cancelled by user")
            return
        except Exception as e:
            print(f"\nError in iteration {iteration}: {str(e)}")
            continue

    print("\n=== Final Summary ===")
    print(f"Total successful iterations: {global_successful_iterations}")
    print(f"Total failed iterations: {global_failed_iterations}")
    print(f"Total applies completed: {apply_count}")
    print(f"Total removes completed: {remove_count}")
    print(
        f"Final successful devices ({len(global_successful_devices)}): {', '.join(global_successful_devices)}")
    print(
        f"Final failed devices ({len(global_failed_devices)}): {', '.join(global_failed_devices)}")


def main():
    try:
        print("=== Automation Tool Execution Wrapper ===")
        run_iterations()
    except Exception as e:
        print(f"\nAn error occurred in main: {str(e)}")


if __name__ == "__main__":
    main()
