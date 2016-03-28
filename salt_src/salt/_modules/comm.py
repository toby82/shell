def file_managed(name, template, source, defaults, filemode='770'):
    source_hash=""
    sfn, source_sum, comment_ = __salt__['file.get_managed'](
        name,
        template,
        source,
        source_hash,
        'root',
        'root',
        filemode,
        'base',
        None,
        defaults
    )
    
    ret = __salt__['file.manage_file'](
        name,
        sfn,
        {},
        source,
        source_sum,
        'root',
        'root',
        filemode,
        'base',
        '',
        makedirs=True
    )
    return ret
