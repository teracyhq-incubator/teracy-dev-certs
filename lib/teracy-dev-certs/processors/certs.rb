require 'fileutils'

require 'teracy-dev'
require 'teracy-dev/processors/processor'

module TeracyDevCerts
  module Processors
    class Certs < TeracyDev::Processors::Processor

      def process(settings)
        @logger.debug("settings: #{settings}")
        certs_config = settings['teracy-dev-certs']
        # make sure node_id exists
        node_id = certs_config['node_id']
        node = settings['nodes'].find { |node| node['_id'] == node_id }
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
        if TeracyDev::Util.exist?(certs_config['ansible_mode']) and !TeracyDev::Util.exist?(certs_config['ansible']['mode'])
          certs_config['ansible']['mode'] = certs_config['ansible_mode']
          @logger.warn("ansible_mode is deprecated, please use ansible.mode instead")
        end

        ansible_type = "ansible_local" # guest by default
        ansible_type = "ansible" if certs_config['ansible']['mode'] == 'host'
        extra_vars = {
          "common_name" => certs_config['common_name'],
          "alt_names" => certs_config['alt_names'],
          "ca_days" => certs_config['ca_days'],
          "cert_days" => certs_config['cert_days'],
          "certs_path" => '/vagrant/workspace/certs'
        }

        if certs_config['ansible']['mode'] == 'guest'
          ansible_install_mode = certs_config['ansible']['install_mode']
          ansible_install_mode = 'pip' unless TeracyDev::Util.exist?(certs_config['ansible']['install_mode'])

          ansible_install_version = certs_config['ansible']['version']
          ansible_install_version = 'latest' unless TeracyDev::Util.exist?(certs_config['ansible']['version'])

          provisioner = {
            "_id" => "certs-ansible",
            "type" => ansible_type,
            "extra_vars" => extra_vars,
            "install_mode" => ansible_install_mode,
            "version" => ansible_install_version
          }
        elsif certs_config['ansible']['mode'] == 'host'
          provisioner = {
            "_id" => "certs-ansible",
            "type" => ansible_type,
            "extra_vars" => extra_vars
          }
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
