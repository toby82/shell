#!py
#coding:utf-8
"""
返回minion对应的pillar信息
"""
import yaml
import os
 
def run():
  """
  首先获取请求的salt id，例如id是：1.2.3.4-centos.game.web,然后根据获取的pillar_root组合成路径/srv/pillar/custom/1.2.3.4-centos.game.web
如果文件存在,利用yaml模块从文件中读取信息，返回字典
如果文件不存在，则返回空
  """
  config={}
  id=__opts__['id']
  pillar_root=__opts__['pillar_roots']['base'][0]
  path='%s/custom/%s'%(pillar_root,id)
  if os.path.isfile(path):
    s=open(path).read()
    config=yaml.load(s)
  return config
