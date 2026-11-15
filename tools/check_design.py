"""Cross-file checks for these lab templates, not an IOS parser or simulator."""
import csv
import json
from ipaddress import ip_address, ip_network
from pathlib import Path


def sections(text):
    result = {}
    current = None
    for line in text.splitlines():
        if line and not line.startswith((' ', '!')):
            current = line
            if current in result:
                raise ValueError(f'Duplicate stanza: {current}')
            result[current] = []
        elif line.startswith(' ') and current:
            result[current].append(line.strip())
    return result


def validate(config, router, switch, pools):
    """Return actionable errors; do not mutate any configuration."""
    r, s = sections(router), sections(switch)
    errors = []
    def require(condition, message):
        if not condition:
            errors.append(message)
    vlans = config['vlans']
    nets = [ip_network(v['network']) for v in vlans]
    require(len({v['id'] for v in vlans}) == len(vlans), 'Duplicate VLAN ID')
    for i, v in enumerate(vlans):
        net = nets[i]
        gateway = ip_address(v['gateway'])
        require(net.network_address < gateway < net.broadcast_address, f"VLAN {v['id']}: unusable gateway")
        require(not any(net.overlaps(other) for other in nets[i+1:]), 'Overlapping subnets')
        body = r.get(f"interface GigabitEthernet0/0.{v['id']}", [])
        require(f"encapsulation dot1Q {v['id']}" in body, f"VLAN {v['id']}: tag mismatch")
        require(f"ip address {v['gateway']} {net.netmask}" in body, f"VLAN {v['id']}: gateway/mask mismatch")
        require(f"vlan {v['id']}" in s, f"VLAN {v['id']}: absent on switch")
        helpers = [x for x in body if x.startswith('ip helper-address ')]
        require(helpers == ([f"ip helper-address {config['dcAddress']}"] if v['dhcp'] == 'server' else []), f"VLAN {v['id']}: relay mismatch")
        if v['start']:
            start, end = ip_address(v['start']), ip_address(v['end'])
            require(net.network_address < start <= end < net.broadcast_address, f"VLAN {v['id']}: pool outside usable range")
            reserved = [gateway, ip_address(config['dcAddress']), ip_address(config['fileServerAddress']), ip_address('10.10.20.2')]
            require(not any(start <= host <= end for host in reserved), f"VLAN {v['id']}: reserved address in pool")
        if v['dhcp'] == 'server':
            matches = [p for p in pools if p['Name'] == v['name']]
            require(len(matches) == 1, f"VLAN {v['id']}: missing/duplicate DHCP pool")
            if len(matches) == 1:
                p = matches[0]
                expected = dict(Network=str(net.network_address), Mask=str(net.netmask), Gateway=str(gateway), Dns=config['dcAddress'], Start=v['start'], MaximumUsers=str(int(end)-int(start)+1))
                for key, value in expected.items():
                    require(p[key] == value, f"VLAN {v['id']}: DHCP {key} mismatch")
        if v['dhcp'] == 'router':
            pool = r.get('ip dhcp pool GUESTS', [])
            require(f'network {net.network_address} {net.netmask}' in pool, 'Guest DHCP network mismatch')
            require(f'default-router {gateway}' in pool, 'Guest DHCP gateway mismatch')
            require('dns-server 198.51.100.10' in pool, 'Guest DHCP DNS mismatch')
            require(f'ip dhcp excluded-address {net.network_address+1} {start-1}' in r, 'Guest lower exclusion mismatch')
            require(f'ip dhcp excluded-address {end+1} {net.broadcast_address-1}' in r, 'Guest upper exclusion mismatch')
        expected_acl = {10:'EMPLOYEE_IN',30:'GUEST_IN',50:'HR_IN',60:'FINANCE_IN'}.get(v['id'])
        bindings = [x for x in body if x.startswith('ip access-group ')]
        require(bindings == ([f'ip access-group {expected_acl} in'] if expected_acl else []), f"VLAN {v['id']}: ACL binding mismatch")
        if expected_acl:
            require(f'ip access-list extended {expected_acl}' in r, f'Missing {expected_acl}')
    allowed = ','.join(map(str, sorted([v['id'] for v in vlans]+[999])))
    trunk = s.get('interface GigabitEthernet0/1', [])
    for command in ['switchport mode trunk', 'switchport trunk native vlan 999', f'switchport trunk allowed vlan {allowed}', 'no shutdown']:
        require(command in trunk, f'Trunk missing: {command}')
    require('encapsulation dot1Q 999 native' in r.get('interface GigabitEthernet0/0.999', []), 'Router native VLAN mismatch')
    require('no shutdown' in r.get('interface GigabitEthernet0/0', []), 'Router uplink disabled')
    require('ip address 10.10.20.2 255.255.255.224' in s.get('interface vlan 20', []), 'Switch management address mismatch')
    require('ip default-gateway 10.10.20.1' in s, 'Switch default gateway mismatch')
    for header, body in s.items():
        if header.startswith(('interface FastEthernet', 'interface range FastEthernet')):
            memberships = [int(x.split()[-1]) for x in body if x.startswith('switchport access vlan ')]
            require(len(memberships) == 1 and memberships[0] in [v['id'] for v in vlans]+[999], f'{header}: invalid access VLAN')
            require('switchport mode access' in body, f'{header}: access mode missing')
            if memberships == [999]:
                require('shutdown' in body, f'{header}: unused port enabled')
    ports = {10:'1 - 4',20:'5 - 6',30:'7 - 8',40:'9 - 10',50:'11 - 12',60:'13 - 14'}
    for vlan in vlans:
        header = f"interface range FastEthernet0/{ports[vlan['id']]}"
        require(f"switchport access vlan {vlan['id']}" in s.get(header, []), f"VLAN {vlan['id']}: access-port mapping mismatch")
    require(len(pools) == sum(v['dhcp']=='server' for v in vlans), 'Unexpected DHCP pools')
    return errors


def check(root):
    root = Path(root)
    inventory = root/'lab.json' if (root/'lab.json').exists() else root.parent/'config/lab.json'
    return validate(json.loads(inventory.read_text()), (root/'R1.cfg').read_text(), (root/'SW1.cfg').read_text(), list(csv.DictReader((root/'dhcp-pools.csv').read_text().splitlines())))


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('directory', type=Path)
    args = parser.parse_args()
    problems = check(args.directory)
    for problem in problems:
        print(problem)
    print('FAIL' if problems else 'PASS: static design consistency only')
    raise SystemExit(bool(problems))
