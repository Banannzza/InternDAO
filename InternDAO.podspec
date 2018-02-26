Pod::Spec.new do |s|

# 1
s.platform = :ios
s.ios.deployment_target = '10.0'
s.name = "InternDAO"
s.summary = "InternDAO"
s.requires_arc = true

# 2
s.version = "0.1.0"

# 3
s.license = { :type => "MIT", :file => "LICENSE" }

# 4 - Replace with your name and e-mail address
s.author = { "[Aleksey Ostapenko]" => "[lek-ostapenko@yandex.ru]" }

# 5 - Replace this URL with your own Github page's URL (from the address bar)
s.homepage = "[Your RWPickFlavor Homepage URL Goes Here]"

# For example,
# s.homepage = "https://github.com/Banannzza/InternDAO"

# 6 - Replace this URL with your own Git URL from "Quick Setup"
 s.source = { :git => "https://github.com/Banannzza/InternDAO.git, :tag => "#{s.version}"}

# 7
s.dependency 'CouchbaseLiteSwift', :git => 'https://github.com/couchbase/couchbase-lite-ios.git', :tag => '2.0DB022', :submodules => true
s.dependency 'SQLite3'

# 8
s.source_files = "InternDAO/**/*.{swift}"

# 9
#s.resources = "RWPickFlavor/**/*.{png,jpeg,jpg,storyboard,xib}"
end
