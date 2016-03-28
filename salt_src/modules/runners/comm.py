import salt.client
import salt.pillar
import salt.runner
import salt.runners.pillar
import pprint
import re

def get_pillar(__opts__, minion='*', **kwargs):
    saltenv = 'base'
    id_, grains, _ = salt.utils.minions.get_minion_data(minion, __opts__)
    if grains is None:
        grains = {'fqdn': minion}

    for key in kwargs:
        if key == 'saltenv':
            saltenv = kwargs[key]
        else:
            grains[key] = kwargs[key]

    pillar = salt.pillar.Pillar(
        __opts__,
        grains,
        id_,
        saltenv)
    compiled_pillar = pillar.compile_pillar()
    return compiled_pillar 

#def show():
#    client = salt.client.LocalClient(__opts__['conf_file'])
#    runner = salt.runner.RunnerClient(__opts__)
#    #pillar = runner.cmd('pillar.show_pillar', [])
#    #print pillar
#    return get_pillar()
     
def get_dic_value(dic, key_strs, default=""):
    key_list = key_strs.split(":")
    key = key_list[0]
    if key == "":
        return default
    if len(key_list) > 1:
        if dic.has_key(key):
            tmp_dic = dic[key]
            tmp_posi = key_strs.index(":") + 1
            tmp_key_strs = key_strs[tmp_posi : ]
            return get_dic_value(tmp_dic, tmp_key_strs, default)
        else:
            return default
    else:
        if dic.has_key(key) and dic[key] is not None:
            value = dic[key]
            if isinstance(value,basestring):
                value = value.strip()
            return value
        else:
            return default

def split_with_comma(str):
    return re.split(', *', str)

def join(value_list, separator=','):
    newlist = []
    for value in value_list:
        if value is None:
            continue
        value = str(value)
        if len(value) == 0:
            continue
        newlist.append(value)
    return separator.join(newlist)

def join_str(orig_str, append_str, separator=','):
    joined_str = orig_str
    if len(joined_str) > 0:
        joined_str = joined_str + separator + append_str
    else:
        joined_str = append_str
    return joined_str



