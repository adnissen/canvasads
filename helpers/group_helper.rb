def insert_ad_to_group(group, ad)
  group.ads << ad.id
  group.save!
  return 200
end
