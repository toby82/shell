################################
# 配置 "管理网络"的各服务器的主机名
################################
mg_nw:
  hosts:
    present:
      # 列出所有在线主机节点名
      # 格式：
      #   控制节点：cc{数字}.域名.域名
      #   计算节点：nc{数字}.域名.域名
      #   网络节点：nn{数字}.域名.域名
      #   自动化部署节点：autodeploy.域名.域名
      cc12.chinacloud.com: 172.16.70.12
      nc13.chinacloud.com: 172.16.70.13
      nc17.chinacloud.com: 172.16.70.17


####
# 删除主机名时如下使用 (将自动修改/etc/hosts)
#    absent:
#      test.chinacloud: 10.4.4.4


################################
# 配置 Openstack 角色和服务器的关系
################################
iaas_role:
  # 控制节点角色的主机名
  cc: cc12.chinacloud.com

  # 计算节点主机名(正则表达式，勿修改)
  #   规则为：
  #     [可有前缀]nc<数字>.各级域名
  #     例如：nc12.chinacloud
  #           iaas-nc01.chinacloud
  # 仅包含计算节点的主机名表达式：
  nc: '.*nc\S*\..*'
  # 包含 计算节点 + 控制节点 的主机名表达式：
  #nc: '.*nc|cc\S*\..*'

  # 网络节点角色的主机名
  nn: cc12.chinacloud.com

  # 部署服务器角色的主机名
  autodeploy: cc12.chinacloud.com

  # vmware agent节点主机名
  # (不能配置为 glusterfs 的服务节点)
  vmw_agent: nc17.chinacloud.com
  
  
################################
# 配置 每台服务器的存储网络
################################


################################
# 配置 Neutron
################################
neutron_info:
  # 数据网络
  pri_if: eth1
  # 外网（被配置用于浮动IP，外网映射）
  pub_if: eth0


################################
# 配置计算节点HA
################################
ncha_info:
  #用于计算节点HA通讯网段
  serviceipseg: 169.254.254.0
  servicegateway: 169.254.254.1
  #存储检测间隔时间
  interval: 120

################################
# 配置 Nova
################################
nova_info:
  ## 配置使用ceph rbd ##
  # 对接ceph前，须从ceph服务器上拷贝 /etc/ceph/ceph.conf，
  # 覆盖部署服务器的ceph配置文件模板 /srv/salt/ceph/template/ceph.conf 
  #backend: rbd
  ## cehp存储的 RBD POOL
  #rbd_image_pool: images-vol 

################################
# 配置 Glance
################################
glance_info:
  ## 配置使用ceph rbd ##
  # 对接ceph前，须从ceph服务器上拷贝 /etc/ceph/ceph.conf，
  # 覆盖部署服务器的ceph配置文件模板 /srv/salt/ceph/template/ceph.conf 
  #backend: rbd
  ## cehp存储的 RBD POOL
  #rbd_image_pool: images-vol
  ## 设置chunk size，即切割的大小
  #rbd_chunk_size: 8

################################
# 配置 Cinder
################################
cinder_info:
  ## 配置使用ceph rbd ##
  # 对接ceph前，须从ceph服务器上拷贝 /etc/ceph/ceph.conf，
  # 覆盖部署服务器的ceph配置文件模板 /srv/salt/ceph/template/ceph.conf 
  #backend: rbd
  ## cehp存储的 RBD POOL
  #rbd_image_pool: volumes
  ## 克隆最大深度
  #rbd_max_clone_path: 5

  ## 配置使用gluster ##
  backend: gluster
  # 使用存储网段IP地址（没有的情况下可使用管理网段）
  gluster_mounts: 172.16.70.12:/cinder-vol

  ## 配置使用 ocfs2 ##
  #backend: ocfs2
  #ocfs2_mounts: /var/lib/cinder/ocfs2-volumes

  ## lvm卷的配置
  #是否可用lvm volumes: y表示使用，n表示不使用
  lvm_enable: n
  lvm_volumes_size: "50G"

################################
# 配置 Ironic
################################
ironic_info:
  # y表示安装，n表示不安装
  # 如果选择了y，则控制节点上 nova_compute服务的driver，将使用 ironic 驱动。
  install: y


################################
# 配置 到存储设备LUN的连接
################################
lun_info:
  # 是否激活
  enable: False
  # 配置逻辑单元号
  lun_number:
    glance_lun: 1
    nova_lun: 1
    cinder_lun: 2
  nodes:
  # 有两个机头的情况下，列举出两条机头IP和iqn值。
  # 仅一个机头的情况下，写出一条机头IP和iqn值即可
    192.168.100.204:3260:
      iqn: iqn.2004-08.tw.com.qsan:q500-p20-00691ae80:dev0.ctr1
    192.168.100.205:3260:
      iqn: iqn.2004-08.tw.com.qsan:q500-p20-00691ae80:dev0.ctr2


################################
# 配置 OCFS2 集群
################################
ocfs2_cluster:
  # 是否激活
  enable: False
  # 集群名字
  name: ocfs2
  service_port: 7777
  #需挂载ocfs2文件夹的节点（包括控制节点和所有计算节点）
  nodes:
    - cc1.chinacloud
    - nc1.chinacloud


################################
# 配置 Glusterfs 集群  服务端/客户端
################################
glusterfs:
  # 是否激活
  enable: True
  # 副本数
  #  replica: 0 表示数据冗余为0，仅有一份数据保存在集群中
  #  replica: 2 表示数据冗余为1，共有两份相同的数据保存在集群中
  replica: 0
  # 承载共享存储的网络（通常使用存储网络，无存储网络的情况下，请选择管理网络。）
  # 管理网络配置项为 mg_nw
  network: mg_nw
  nodes:
    - cc12.chinacloud.com:
        # 角色分为 server, client。 server将作为集群的一个节点，同时也部署了client；而client仅作为客户端访问集群。
        role: server
    - nc13.chinacloud.com:
        role: server
 
include:
  - others.glusterfs
  - others.yum_repos
  - others.nebula4j
  - others.others
  - others.keystone
  - others.glance
  - others.nova
  - others.db_info
  - others.ceph
