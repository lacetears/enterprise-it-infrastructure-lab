import copy
import csv
import json
import unittest
from pathlib import Path
from tools.check_design import check, validate
from tools.acl_model import load_acls, permits
ROOT = Path(__file__).resolve().parents[1]

class DesignTests(unittest.TestCase):
    def test_both_designs(self):
        for folder in ('network','network/departments'):
            with self.subTest(folder=folder):
                self.assertEqual(check(ROOT/folder), [])

    def test_mutations_are_detected(self):
        root=ROOT/'network/departments'
        config=json.loads((root/'lab.json').read_text())
        router=(root/'R1.cfg').read_text()
        switch=(root/'SW1.cfg').read_text()
        pools=list(csv.DictReader((root/'dhcp-pools.csv').read_text().splitlines()))
        mutations=[('router mask',router.replace('10.10.50.1 255.255.255.224','10.10.50.1 255.255.255.0'),switch),
                   ('missing relay',router.replace('ip helper-address 10.10.40.10','ip helper-address 10.10.40.11',1),switch),
                   ('ACL direction',router.replace('HR_IN in','HR_IN out'),switch),
                   ('trunk omitted HR',router,switch.replace('10,20,30,40,50,60,999','10,20,30,40,60,999')),
                   ('access port wrong VLAN',router,switch.replace('switchport access vlan 50','switchport access vlan 60')),
                   ('native mismatch',router,switch.replace('native vlan 999','native vlan 1')),
                   ('wrong tag',router.replace('dot1Q 50','dot1Q 51'),switch)]
        for name,r,s in mutations:
            with self.subTest(name=name): self.assertTrue(validate(config,r,s,pools))
        for key in ('Mask','Gateway','Dns','MaximumUsers'):
            changed=copy.deepcopy(pools);changed[0][key]='wrong'
            with self.subTest(pool=key):self.assertTrue(validate(config,router,switch,changed))

    def test_department_acl_paths(self):
        rules=load_acls((ROOT/'network/departments/R1.cfg').read_text())
        for vlan,acl in [(10,'EMPLOYEE_IN'),(50,'HR_IN'),(60,'FINANCE_IN')]:
            source=f'10.10.{vlan}.10'
            cases=[('udp','0.0.0.0','255.255.255.255',68,67,True),
                   ('udp',source,'10.10.40.10',50000,53,True),
                   ('tcp',source,'10.10.40.11',50000,80,True),
                   ('tcp',source,'10.10.20.2',50000,22,False),
                   ('tcp',source,'198.51.100.10',50000,443,False)]
            for other in (10,50,60):
                if other!=vlan:cases.append(('tcp',source,f'10.10.{other}.10',50000,445,False))
            for protocol,src,dst,sport,dport,expected in cases:
                with self.subTest(acl=acl,destination=dst):
                    self.assertEqual(permits(rules[acl],dict(protocol=protocol,source=src,destination=dst,sport=sport,dport=dport)),expected)

if __name__=='__main__':unittest.main()
