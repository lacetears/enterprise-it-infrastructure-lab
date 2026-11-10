"""Small, deliberately limited evaluator for the supplied IOS extended ACL syntax.
Fails on unsupported tokens. Does not simulate switching, routing, TCP state or IOS.
"""
from ipaddress import IPv4Address

def address(tokens):
    token=tokens.pop(0)
    if token=='any': return lambda value: True
    if token=='host':
        target=IPv4Address(tokens.pop(0)); return lambda value: IPv4Address(value)==target
    base=int(IPv4Address(token)); wildcard=int(IPv4Address(tokens.pop(0)))
    mask=0xffffffff ^ wildcard
    return lambda value: int(IPv4Address(value)) & mask == base & mask

def parse_rule(line):
    tokens=line.split(); action=tokens.pop(0); protocol=tokens.pop(0)
    if action not in ('permit','deny') or protocol not in ('ip','tcp','udp','icmp'): raise ValueError(line)
    source=address(tokens); sport=None; dport=None
    if tokens and tokens[0]=='eq': tokens.pop(0); sport=int(tokens.pop(0))
    destination=address(tokens)
    if tokens and tokens[0]=='eq': tokens.pop(0); dport=int(tokens.pop(0))
    icmp=None
    if tokens==['echo']: icmp='echo';tokens=[]
    if tokens: raise ValueError(f'Unsupported ACL tokens: {tokens}')
    return action,protocol,source,sport,destination,dport,icmp

def load_acls(text):
    result={}; current=None
    for raw in text.splitlines():
        if raw.startswith('ip access-list extended '): current=raw.split()[-1];result[current]=[]
        elif raw.startswith(' ') and current:
            result[current].append(parse_rule(raw.strip()))
        elif raw.strip() and not raw.startswith('!'): current=None
    return result

def permits(rules,packet):
    for action,protocol,source,sport,destination,dport,icmp in rules:
        if protocol not in ('ip',packet['protocol']): continue
        if not source(packet['source']) or not destination(packet['destination']): continue
        if sport is not None and sport!=packet.get('sport'): continue
        if dport is not None and dport!=packet.get('dport'): continue
        if icmp is not None and icmp!=packet.get('icmp'): continue
        return action=='permit'
    return False
