$circuit_path = '/home/oneops'
require "#{$circuit_path}/circuit-oneops-1/components/spec_helper.rb"
require "#{$circuit_path}/circuit-oneops-1/components/cookbooks/volume/test/integration/volume_helper.rb"

size = $ciAttr['size']
fs_type = $ciAttr['fstype']
options = $ciAttr['options']
options_hash = Hash[options.split(',').map {|i| [i.split('=')[0].to_sym, i.split('=')[1] ? i.split('=')[1] : true]}]

#Check if the $mount_point is a directory, mounted with correct filesystem and writeable
mount_hash = {}
mount_hash[:type] = fs_type
mount_hash[:device] = $ciAttr['device'] unless $ciAttr['device'].nil? || $ciAttr['device'].empty?
mount_hash[:options] = options_hash unless options_hash.empty?

describe file($mount_point) do
  it { should be_directory }
  it { should be_mounted.with( mount_hash) }
end

#assert each storage device from the map
$device_map.each do |dev|
  if dev.split(':').size > 2
    resource_group_name, storage_account_name, ciID, slice_size, dev_id = dev.split(':')
    vol_id = [ciID, 'datadisk',dev.split('/').last.to_s].join('-')
  else
    vol_id, dev_id = dev.split(":")
  end

  reg = Regexp.new( "^#{Regexp.escape(dev_id)}:#{Regexp.escape(dev_id[0..dev_id.length-2])}\\w$" )

  describe file("/opt/oneops/storage_devices/#{vol_id}") do
    it { should be_file }
    its(:content) {should match reg}
  end

end if $storage

#Assert volume size
size_vm = `df -BG | grep #{$mount_point}| awk '{print $2}'`.chop.to_i
vg = `vgdisplay -c`
vg_size = ((vg.split(':')[11].to_f)/1024/1024).round(0).to_i
vg_lvcount = vg.split(':')[5].to_i

size_wo_g = nil
if size =~ /^\d+G$/           #size specified in Gb - 100G
  size_wo_g = size.to_i
elsif size =~ /^\d+T$/        #size specified in Tb - 1T
  size_wo_g = size.to_i * 1024
elsif size =~ /^\d+\%VG$/     #size specified in % of VG - 70%VG
  size_wo_g = (vg_size.to_f * size.gsub('%VG','').to_i / 100).round(0).to_i
elsif size =~ /^\d+\%FREE$/ && vg_lvcount == 1  #size specified in % of free space in VG - 70%FREE - can only calculate with 1 volume component
  size_wo_g = (vg_size.to_f * size.gsub('%FREE','').to_i / 100).round(0).to_i
else
  puts "Cannot calculate absolute size"
end

describe "size of #{$mount_point}" do
  it "matches requested" do
    expect(size_wo_g).to eql(size_vm)
  end
end unless size_wo_g.nil?
