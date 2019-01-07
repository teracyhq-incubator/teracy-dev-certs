require 'fileutils'

require 'teracy-dev'
require 'teracy-dev/util'
require 'teracy-dev/processors/processor'

module TeracyDevCerts
  module Processors
    class Certs < TeracyDev::Processors::Processor

      def process(settings)
        @logger.debug("settings: #{settings}")
        certs_config = settings['teracy-dev-certs']
        node_id = certs_config['node_id']
        node = settings['nodes'].find { |node| node['_id'] == node_id }
        # try with _id_deprecated
        if node == nil
          node = settings['nodes'].find { |node| node['_id_deprecated'] == node_id }
          # this works well with teracy-dev-core >= v0.4.0 (when its _id is changed on v0.5.0)
          # update certs_config['node_id'] to use the _id, not _id_deprecated to avoid warning message
          @logger.debug("node: #{node}")
          if node != nil
            certs_config['node_id'] = node['_id']
          end
        end
        # make sure node with its specified id (node_id) exists
        if node == nil
          @logger.error("node not found for node_id: #{node_id}")
          abort
        end

        setup(certs_config)
        nodes = [generate_node(certs_config)]
        TeracyDev::Util.override(settings, {"nodes" => nodes})
      end

      private

      def setup(certs_config)
        @logger.debug("certs_config: #{certs_config}")
        # create the workspace/certs directory if not exist yet
        certs_dir = File.join(TeracyDev::BASE_DIR, 'workspace', 'certs')
        FileUtils.mkdir_p certs_dir
      end

      def generate_node(certs_config)
        if TeracyDev::Util.exist?(certs_config['ansible_mode'])
          certs_config['ansible']['mode'] = certs_config['ansible_mode']
          @logger.warn("ansible_mode is deprecated, please use ansible.mode instead")
        end

        ansible_type = "ansible_local" # guest by default
        ansible_type = "ansible" if certs_config['ansible']['mode'] == 'host'
        extra_vars = {
          "common_name" => certs_config['common_name'],
          "alt_names" => certs_config['alt_names'],
          "ca_days" => certs_config['ca_days'],
          "certs_path" => '/vagrant/workspace/certs'
        }

        if TeracyDev::Util.exist?(certs_config['cert_days'])
          certs_config['cert']['days'] = certs_config['cert_days']

          @logger.warn("cert_days is deprecated, please use cert.days instead")
        end

        extra_vars['cert_days'] = certs_config['cert']['days']

        if TeracyDev::Util.exist? certs_config['cert']['generated'] and TeracyDev::Util.true? certs_config['cert']['generated']
          certs_config['cert']['generated'] = true
        else
          certs_config['cert']['generated'] = false
        end

        extra_vars['cert_generated'] = certs_config['cert']['generated']

        provisioner = {
          "_id" => "certs-ansible",
          "type" => ansible_type,
          "extra_vars" => extra_vars
        }

        if certs_config['ansible']['mode'] == 'guest'
          ansible_install_mode = certs_config['ansible']['install_mode']

          provisioner['install_mode'] = ansible_install_mode if TeracyDev::Util.exist? ansible_install_mode

          ansible_version = certs_config['ansible']['version']

          provisioner['version'] = ansible_version if TeracyDev::Util.exist? ansible_version
        end

        node = {
          "_id" => certs_config['node_id'],
          "provisioners" => [provisioner]
        }

        node_template = certs_config['node_template']

        node = TeracyDev::Util.override(node_template, node)

        @logger.debug("node: #{node}")

        node
      end
    end
  end
end
