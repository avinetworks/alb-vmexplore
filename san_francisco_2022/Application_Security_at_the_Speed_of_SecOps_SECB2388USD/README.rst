Avi Ansible Training Site Example
``````````````````````````````
.. contents::
  :local:

This is an example of setting up a full Avi Site with Cloud and applications. Note This version is compatible with Ansible 2.4 only.

*********
Installation
*********

The site example requires avinetworks.avisdk and avinetworks.aviconfig roles.
Please install them from Ansible galaxy using following command

.. code-block:: shell

  pip install avisdk
  ansible-galaxy collection install vmware.alb

*********
Site Layout 
*********
Here are the main components of the site example.
- `site.yml <https://github.com/avinetworks/devops/blob/master/ansible/training/site-example/site.yml>`_: This describes the playbooks for setup of the site. It includes sections for cloud setup and application setup.

Usage for full site setup

.. code-block:: shell
  
  ansible-playbook site.yml --extra-vars "avi_username=chooseyourown site_dir=`pwd`"

Usage for just cloud setup

.. code-block:: shell
  
  ansible-playbook site_clouds.yml --extra-vars "avi_username=chooseyourown site_dir=`pwd`"

Usage for just applications setup. This would setup all the applications that are registered in site_applications.yml

.. code-block:: shell
  
  ansible-playbook site_applications.yml --extra-vars "avi_username=chooseyourown site_dir=`pwd`"

Usage to delete all applications in the site_applications.yml. The flag avi_config_state=absent will override the individual object state for deletion purpose.

.. code-block:: shell
  
  ansible-playbook site_applications.yml --extra-vars "avi_username=chooseyourown site_dir=`pwd` avi_config_state=absent"

************
Roles
************

The roles directory contains AviConfig role that has ability to process a configuration file with avi configurations that is listed on a per-resource type. It performs the configuration in the right order as required by the object dependencies.

************
Applications
************
All the site applications are registered in the `site_applications.yml <site_applications.yml>`_. The configuration files for the applications are kept in the `applications <applications>`_ directory. Each applications directory contains `config.yml <applications/app1/config.yml>`_ that represents all Avi RESTful objects that are needed for the application. In addition, there is an playbook for setting up application eg. `app.yml <applications/app1/app.yml>`_. The example only configures Avi settings but this playbook can be extended to create VMs, create SSL certs etc. The `app1 <applications/app1>`_ contains one pool and one l7 virtualservice with VIP 10.90.64.240. 

Here are steps to enable the application Here are the step:

-------------------
Basic Application
-------------------

1. Register in the `site_applications.yml <site_applications.yml>`_:

.. code-block:: yaml

    - include: applications/app1/app.yml

2. Create app1 directory under applications and create `config.yml <applications/app1/config.yml>`_ for the application.

.. code-block:: yaml

    avi_config:
      pool:
        - name: app1-pool
          lb_algorithm: LB_ALGORITHM_ROUND_ROBIN
          servers:
            - ip:
                 addr: 'x.y.z.a'
                 type: 'V4'
            - ip:
                 addr: 'x.y.z.b'
                 type: 'V4'

      virtualservice:
        - name: app1
          services:
            - port: 80
          pool_ref: '/api/pool?name=app1-pool'
          vip:
            - ip_address:
                addr: x.y.z.c
                type: 'V4'
              vip_id: '1'

3. Create `app.yml <applications/app1/app.yml>`_ playbook under the applications directory

.. code-block:: yaml

  ---
  - hosts: localhost
    connection: local
    vars:
      api_version: 17.1.2
      app_name: app1

    roles:
      - role: vmware.alb

    tasks:
      - name: Setting up Application
        debug: msg="{{ app_name }}"

      - name: Avi Application | Setup VMWare Cloud with Write Access
        import_role:
          name: aviconfig
        vars:
          avi_config_file: "{{ site_dir }}/applications/{{app_name}}/config.yml"
          avi_creds_file: "{{ site_dir }}/vars/creds.yml"
