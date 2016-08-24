=begin
 list_rhev_cloudinit_template_ids.rb

 Author: Kevin Morey <kevin@redhat.com>

 Description: This method lists cloud-init customization template ids that reside in the RHEV System Image Type or
  that contain the word 'rhev'
-------------------------------------------------------------------------------
   Copyright 2016 Kevin Morey <kevin@redhat.com>

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
-------------------------------------------------------------------------------
=end
def log(level, msg, update_message = false)
  $evm.log(level, "#{msg}")
  @task.message = msg if @task && (update_message || level == 'error')
end

def search_customization_templates_by_name(search_string, customization_templates = [])
  customization_templates = $evm.vmdb(:customization_template_cloud_init).all.select do |ct|
    ct.name.downcase.include?(search_string)
  end
  if customization_templates
    log(:info, "Found #{customization_templates.count} customization_templates via name: #{search_string}")
  end
  customization_templates
end

def search_customization_templates_by_image_type(search_string, customization_templates = [])
  image_type = $evm.vmdb(:pxe_image_type).all.detect do |pit|
    next unless pit.name
    pit.name.downcase.include?(search_string)
  end
  if image_type
    customization_templates = image_type.customization_templates rescue []
    log(:info, "Found #{customization_templates.count} customization_templates via image_type: #{search_string}")
  end
  customization_templates
end

def customization_template_eligible?(customization_template)
  return false unless customization_template.type == "CustomizationTemplateCloudInit"
  return false if customization_template.name.nil?
  true
end

$evm.root.attributes.sort.each { |k, v| log(:info, "\t Attribute: #{k} = #{v}")}

dialog_hash = {}
customization_templates = search_customization_templates_by_image_type('rhev') ||
  search_customization_templates_by_name('rhev') || []

if customization_templates.blank?
  $evm.vmdb(:customization_template_cloud_init).all.each do |ct|
    next if !customization_template_eligible?(ct)
    dialog_hash[ct.id] = ct.name
  end
else
  customization_templates.each do |ct|
    next if !customization_template_eligible?(ct)
    dialog_hash[ct.id] = ct.name
  end
end

if dialog_hash.blank?
  dialog_hash[''] = "< no customization templates found >"
  $evm.object['required'] = false
else
  $evm.object['default_value'] = dialog_hash.first[0]
end

$evm.object["values"]     = dialog_hash
log(:info, "$evm.object['values']: #{$evm.object['values'].inspect}")
