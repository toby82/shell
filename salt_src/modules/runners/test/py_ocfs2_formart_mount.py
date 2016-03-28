import salt.client
import salt.pillar
import salt.loader
import salt.utils.master
import pprint
import comm


client = salt.client.LocalClient()
__opts__ = salt.config.client_config('/etc/salt/master')
pillar = salt.utils.master.MasterPillarUtil("cc1.chinacloud",opts=__opts__)
pillar_dic = pillar.get_minion_pillar()
pillar_dic = pillar.get_minion_grains()
pprint.pprint(pillar_dic)

# client.cmd('*', 'test.ping', timeout=1)

ip_port = ""
iqn = ""
for key_ip, value in pillar_dic['lun_info']['nodes'].items():
    ip_port = key_ip
    iqn = value["iqn"]

glance_lun =  pillar_dic['lun_info']['lun_number']['glance_lun']
glance_mnt_dir = pillar_dic['glance_info']['glance_mnt_dir']

nova_lun =  pillar_dic['lun_info']['lun_number']['nova_lun']
nova_mnt_dir = pillar_dic['nova_info']['nova_mnt_dir']

ocfs2_node = pillar_dic['ocfs2_cluster']['nodes']
for index in range(len(ocfs2_node)):
    hostname = ocfs2_node[index]
    if index == 0:
        #client.cmd(hostname, "salt://ocfs2/script/formart_mount.sh", ip_port, iqn, glance_lun, glance_mnt_dir, "True")
        print '======'
	client.cmd('*', 'cmd.run', ['whoami'], timeout=1)
	
