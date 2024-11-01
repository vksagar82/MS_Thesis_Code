import subprocess
import time
import psutil
import csv
from datetime import datetime
import os
from psutil import Process
from os import getpid
import re

# Create execution_results directory if it doesn't exist
RESULTS_DIR = "execution_results"
if not os.path.exists(RESULTS_DIR):
    os.makedirs(RESULTS_DIR)

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
        "cisco5-65001", "cisco6-65001", "cisco7-65001",
        "cisco8-65003", "cisco4-65002", "cisco5-65002",
        "cisco7-65002", "cisco8-65002", "cisco7-65003",
        "cisco6-65002"
    ],
    'juniper': [
        "juniper1-65001", "juniper2-65001", "juniper3-65001",
        "juniper8-65001", "juniper4-65001", "juniper1-65002",
        "juniper2-65002", "juniper3-65002", "juniper5-65003",
        "juniper6-65003"
    ],
    'arista': [
        "arista9-65001", "arista10-65001", "arista11-65001",
        "arista11-65002", "arista9-65002", "arista10-65002",
        "arista1-65003", "arista2-65003", "arista3-65003",
        "arista4-65003"
    ]
}


def get_operation_choice():
    while True:
        print("\nAvailable operations:")
        print("1. Apply configs")
        print("2. Remove configs")
        try:
            choice = int(input("\nSelect operation (1-2): "))
            if choice in [1, 2]:
                operations = {1: "apply", 2: "remove"}
                return operations[choice]
            print("Please enter either 1 or 2")
        except ValueError:
            print("Please enter a valid number")


def get_playbook_name(operation):
    while True:
        print("\nAvailable playbooks:")
        print("1. one_change")
        print("2. four_changes")
        print("3. all_changes")
        try:
            choice = int(input("\nSelect playbook (1-3): "))
            if choice in [1, 2, 3]:
                playbooks = {
                    1: "one_change",
                    2: "four_changes",
                    3: "all_changes"
                }
                base_playbook = playbooks[choice]
                return f"{base_playbook}_remove" if operation == "remove" else base_playbook
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
        # CPU times
        cpu_times = psutil.cpu_times()
        # Network I/O
        net_io = psutil.net_io_counters()
        # Disk I/O
        disk_io = psutil.disk_io_counters()
        # Memory
        memory = psutil.Process().memory_info()

        return {
            'cpu_times': cpu_times,
            'net_io': net_io,
            'disk_io': disk_io,
            'memory': memory
        }
    except Exception as e:
        print(f"Error getting system metrics: {e}")
        return None


def calculate_resource_usage(start_metrics, end_metrics):
    """Calculate the difference in resource usage"""
    if not (start_metrics and end_metrics):
        return 0, 0, 0, 0, 0

    try:
        # CPU Usage calculation
        start_cpu = start_metrics['cpu_times']
        end_cpu = end_metrics['cpu_times']

        # Calculate total CPU time
        start_total = sum([getattr(start_cpu, field)
                          for field in start_cpu._fields])
        end_total = sum([getattr(end_cpu, field) for field in end_cpu._fields])

        # Calculate user and system CPU time
        start_busy = start_cpu.user + start_cpu.system
        end_busy = end_cpu.user + end_cpu.system

        # Calculate CPU percentage
        if end_total - start_total > 0:
            cpu_percent = ((end_busy - start_busy) /
                           (end_total - start_total)) * 100
        else:
            cpu_percent = 0

        # Memory Usage (MB)
        memory_used = (end_metrics['memory'].rss -
                       start_metrics['memory'].rss) / 1024 / 1024

        # Network I/O (bytes)
        bytes_sent = end_metrics['net_io'].bytes_sent - \
            start_metrics['net_io'].bytes_sent
        bytes_recv = end_metrics['net_io'].bytes_recv - \
            start_metrics['net_io'].bytes_recv

        # Disk I/O (bytes)
        disk_io_bytes = (
            (end_metrics['disk_io'].read_bytes - start_metrics['disk_io'].read_bytes) +
            (end_metrics['disk_io'].write_bytes -
             start_metrics['disk_io'].write_bytes)
        )

        return cpu_percent, memory_used, bytes_sent, bytes_recv, disk_io_bytes

    except Exception as e:
        print(f"Error calculating resource usage: {e}")
        return 0, 0, 0, 0, 0


def execute_ansible_playbook(playbook_name, devices):
    try:
        cmd = f"ansible-playbook playbooks/{playbook_name}.yml -vvvv --limit \"{','.join(devices)}\""
        print(f"\nExecuting command: {cmd}")
        print("\nPlaybook execution in progress...")

        process = subprocess.Popen(
            cmd,
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            bufsize=1,
            universal_newlines=True
        )

        output_lines = []
        show_output = False

        while True:
            line = process.stdout.readline()
            if not line and process.poll() is not None:
                break
            if line:
                output_lines.append(line)
                # Only show PLAY RECAP section
                if "PLAY RECAP" in line:
                    show_output = True
                    print("\n" + line.strip())
                elif show_output:
                    print(line.strip())

        output = ''.join(output_lines)
        stderr_output = process.stderr.read()
        return_code = process.wait()

        return output, stderr_output, return_code, 0

    except Exception as e:
        print(f"Error in execute_ansible_playbook: {e}")
        return None, str(e), 1, 0


def get_output_filename(playbook_name, device_count):
    filename = f"{playbook_name}_{device_count}_devices.csv"
    return os.path.join(RESULTS_DIR, filename)


def main():
    try:
        print("=== Ansible Playbook Execution Wrapper ===")

        operation = get_operation_choice()
        playbook_name = get_playbook_name(operation)
        device_count = get_device_count()
        selected_devices = get_devices_for_config(device_count)

        output_file = get_output_filename(playbook_name, device_count)
        print(f"\nResults will be saved to: {output_file}")

        # Get initial metrics
        start_metrics = get_system_metrics()
        start_time = time.time()

        # Execute playbook
        output, errors, return_code, _ = execute_ansible_playbook(
            playbook_name, selected_devices)

        # Get end metrics
        end_metrics = get_system_metrics()
        execution_time = time.time() - start_time

        # Calculate metrics
        cpu_used, memory_used, net_bytes_sent, net_bytes_recv, disk_io_bytes = calculate_resource_usage(
            start_metrics, end_metrics
        )

        # Calculate throughput
        bytes_per_second = net_bytes_sent / execution_time if execution_time > 0 else 0

        print("\n=== Execution Metrics ===")
        print(f"Execution Time: {execution_time:.2f} seconds")
        print(f"CPU Usage: {cpu_used:.2f}%")
        print(f"Memory Usage: {memory_used:.2f} MB")
        print(f"Network Bytes Sent: {net_bytes_sent} bytes")
        print(f"Network Bytes Received: {net_bytes_recv} bytes")
        print(f"Disk I/O: {disk_io_bytes} bytes")
        print(f"Throughput: {bytes_per_second:.2f} bytes/second")

        if return_code == 0:
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            csv_row = {
                'Timestamp': timestamp,
                'Tool': 'Ansible',
                'Operation': operation,
                'Playbook': playbook_name,
                'Number_of_Devices': device_count,
                'Device_Names': ','.join(selected_devices),
                'Execution_Time': f"{execution_time:.2f}",
                'CPU_Usage': f"{cpu_used:.2f}",
                'Memory_Usage': f"{memory_used:.2f}",
                'Network_Bytes_Sent': str(net_bytes_sent),
                'Network_Bytes_Received': str(net_bytes_recv),
                'Disk_IO_Bytes': str(disk_io_bytes),
                'Throughput': f"{bytes_per_second:.2f}"
            }

            file_exists = os.path.isfile(output_file)
            with open(output_file, 'a', newline='') as csvfile:
                fieldnames = ['Timestamp', 'Tool', 'Operation', 'Playbook',
                              'Number_of_Devices', 'Device_Names', 'Execution_Time',
                              'CPU_Usage', 'Memory_Usage', 'Network_Bytes_Sent',
                              'Network_Bytes_Received', 'Disk_IO_Bytes', 'Throughput']
                writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

                if not file_exists:
                    writer.writeheader()
                writer.writerow(csv_row)

            print(f"\nResults saved to: {output_file}")
            print("\nExecution completed successfully!")
        else:
            print("\nPlaybook execution failed. Results not saved to CSV.")
            if errors:
                print("\n=== Errors ===")
                print(errors)

    except KeyboardInterrupt:
        print("\nExecution cancelled by user")
    except Exception as e:
        print(f"\nAn error occurred: {str(e)}")


if __name__ == "__main__":
    main()
