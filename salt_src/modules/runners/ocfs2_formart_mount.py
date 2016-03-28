import salt.client
import salt.pillar
import salt.runner
import salt.runners.pillar
import pprint
import salt.output
import comm


def run():
    client = salt.client.LocalClient(__opts__['conf_file'])
    runner = salt.runner.RunnerClient(__opts__)
    pillar_dic = comm.get_pillar(__opts__)

    cc_hostname = pillar_dic['iaas_role']['cc']
    ip_port = ""
    iqn = ""
    for key_ip, value in pillar_dic['lun_info']['nodes'].items():
	ip_port = key_ip
        iqn = value["iqn"]

    glance_lun =  pillar_dic['lun_info']['lun_number']['glance_lun']
    glance_mnt_dir = pillar_dic['glance_info']['glance_mnt_dir']

    nova_lun =  pillar_dic['lun_info']['lun_number']['nova_lun']
    nova_mnt_dir = pillar_dic['nova_info']['nova_mnt_dir']

    cinder_lun = pillar_dic['lun_info']['lun_number']['cinder_lun']
    cinder_mnt_dir = pillar_dic['cinder_info']['ocfs2_mounts']

    ocfs2_node = pillar_dic['ocfs2_cluster']['nodes']
    result_list = []

    glance_args_list = [ip_port, iqn, str(glance_lun), glance_mnt_dir, "True"]
    nova_args_list   = [ip_port, iqn, str(nova_lun),   nova_mnt_dir,   "True"]
    cinder_args_list = [ip_port, iqn, str(cinder_lun), cinder_mnt_dir, "True"]

    for index in range(len(ocfs2_node)):
	hostname = ocfs2_node[index]
        mnt_list = []
	if hostname == cc_hostname:
            mnt_list.append(glance_args_list)

        mnt_list.append(nova_args_list)
        mnt_list.append(cinder_args_list)

	if index == 0:
	    for args in mnt_list:
		args_str = " ".join(args)
		result = client.cmd(hostname, "cmd.script", ["salt://ocfs2/script/formart_mount.sh", args_str ])
		result_list.append(result)
	else:
	    for args in mnt_list:
		args[4] = "False"
		args_str = " ".join(args)
                result = client.cmd(hostname, "cmd.script", ["salt://ocfs2/script/formart_mount.sh", args_str ])
		result_list.append(result)
    return result_list
