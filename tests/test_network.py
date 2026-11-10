import csv,json,unittest
from ipaddress import ip_network,ip_address
from pathlib import Path
from tools.acl_model import load_acls,permits,parse_rule
ROOT=Path(__file__).resolve().parents[1]
class NetworkTests(unittest.TestCase):
    def test_address_plan(self):
        vlans=json.loads((ROOT/'config/lab.json').read_text())['vlans']
        networks=[ip_network(v['network']) for v in vlans]
        self.assertEqual(len({v['id'] for v in vlans}),len(vlans))
        for i,v in enumerate(vlans):
            net=networks[i];self.assertIn(ip_address(v['gateway']),net)
            for other in networks[i+1:]:self.assertFalse(net.overlaps(other))
            if v['start']:
                start,end=ip_address(v['start']),ip_address(v['end'])
                self.assertTrue(net.network_address<start<=end<net.broadcast_address)
                self.assertFalse(start<=ip_address(v['gateway'])<=end)
    def test_relay_and_trunk(self):
        r=(ROOT/'network/R1.cfg').read_text();s=(ROOT/'network/SW1.cfg').read_text()
        self.assertEqual(r.count('ip helper-address 10.10.40.10'),2)
        self.assertIn('switchport trunk allowed vlan 10,20,30,40,999',s)
        for v in json.loads((ROOT/'config/lab.json').read_text())['vlans']:
            self.assertIn(f"encapsulation dot1Q {v['id']}",r)
    def test_server_pools(self):
        vlans=json.loads((ROOT/'config/lab.json').read_text())['vlans']
        pools=list(csv.DictReader((ROOT/'network/dhcp-pools.csv').read_text().splitlines()))
        for v in [v for v in vlans if v['dhcp']=='server']:
            pool=next(p for p in pools if p['Name']==v['name'])
            self.assertEqual(pool['Start'],v['start']);self.assertEqual(pool['Gateway'],v['gateway'])
            self.assertEqual(int(ip_address(pool['Start']))+int(pool['MaximumUsers'])-1,int(ip_address(v['end'])))
    def test_policy_cases(self):
        acls=load_acls((ROOT/'network/R1.cfg').read_text())
        cases=json.loads((ROOT/'tests/acl-cases.json').read_text())
        for c in cases:
            with self.subTest(c['name']):self.assertEqual(permits(acls[c['acl']],c),c['permit'])
    def test_unknown_acl_syntax_fails(self):
        with self.assertRaises(ValueError):parse_rule('permit tcp any any established')
    def test_first_match_and_implicit_deny(self):
        rules=[parse_rule('deny ip any host 10.0.0.1'),parse_rule('permit ip any any')]
        packet=dict(protocol='tcp',source='10.0.0.2',destination='10.0.0.1',dport=80)
        self.assertFalse(permits(rules,packet));self.assertFalse(permits([],packet))
    def test_subnet_edges_and_wrong_port(self):
        rules=[parse_rule('permit tcp 10.10.20.0 0.0.0.31 host 10.10.40.10 eq 445')]
        for source,port,expected in [('10.10.20.30',445,True),('10.10.20.32',445,False),('10.10.20.30',22,False)]:
            self.assertEqual(permits(rules,dict(protocol='tcp',source=source,destination='10.10.40.10',dport=port)),expected)
if __name__=='__main__':unittest.main()
