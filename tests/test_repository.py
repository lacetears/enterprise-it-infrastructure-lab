import re,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
class RepositoryTests(unittest.TestCase):
    def test_local_document_links(self):
        for f in ROOT.rglob('*.md'):
            for target in re.findall(r'\]\(([^)]+)\)',f.read_text()):
                if '://' in target or target.startswith('#'):continue
                with self.subTest(file=f.name,target=target):self.assertTrue((f.parent/target.split('#')[0]).exists())
    def test_tickets_have_diagnosis_recovery_and_status(self):
        tickets=list((ROOT/'tickets').glob('[0-9]*.md'));self.assertEqual(len(tickets),10)
        for f in tickets:
            for heading in ['Symptoms','Diagnostic steps','Scenario root cause','Resolution','Verification','Rollback and evidence']:
                self.assertIn('## '+heading,f.read_text())
            self.assertIn('not executed',f.read_text())
    def test_no_secret_artifacts(self):
        forbidden={'.pfx','.key','.pem','.evtx','.iso','.vhdx'}
        for f in ROOT.rglob('*'):
            if '.git' in f.parts:continue
            self.assertNotIn(f.suffix,forbidden)
if __name__=='__main__':unittest.main()
