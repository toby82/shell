import salt.client
import salt.pillar
import salt.runner
import salt.runners.pillar
import pprint
import comm


def get_pillar():
    runner = salt.runner.RunnerClient(__opts__)
    print comm.get_pillar(__opts__)

def ping():
    client = salt.client.LocalClient(__opts__['conf_file'])
    minions = client.cmd('*', 'test.ping', timeout=1)
    for minion in sorted(minions):
        print minion

def ls():
    client = salt.client.LocalClient(__opts__['conf_file'])
    minions = client.cmd('*', 'ls /', timeout=1)
    for minion in sorted(minions):
        print minion
