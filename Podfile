platform :ios, '9.0'

target 'RealmPhotos' do
  use_frameworks!

  pod 'RealmSwift'

  target 'RealmPhotosTests' do
    inherit! :search_paths
    # Pods for testing
  end

end

plugin 'cocoapods-keys', {
  :project => 'RealmPhotos',
  :keys => [
    "RealmUsername",
    "RealmPassword"
  ]
}
