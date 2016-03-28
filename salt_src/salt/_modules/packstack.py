def install_packages():
    if not __salt__['pkg.version']('openstack-packstack'):
        __salt__['pkg.install']('openstack-packstack')

def build_answer_file(defaults):
    local_answer_file_path = defaults['answer_file_path']
    template='jinja'
    remote_answer_file_template = 'salt://packstack/template/answer_customization_eth.txt'
    ret = __salt__['comm.file_managed'](local_answer_file_path, template, remote_answer_file_template, defaults, '770')
    return {'create_anwser_file': ret}

def run_deploy(answer_file_path):
    cmd = 'packstack -d --answer-file %(file_path)s ' % {'file_path': answer_file_path}
    run_env = [
        {"LANG": "en_US.UTF-8"},
        {"LC_ALL": "en_US.UTF-8"},
    ]
    result = __salt__['cmd.run_all'](cmd, env=run_env)
    return {cmd: result}

def deploy_iaas(params):
    install_packages()
    build_answer_file(params)
    answer_file = params['answer_file_path']
    result = run_deploy(answer_file)
    return result