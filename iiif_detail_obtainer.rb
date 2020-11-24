require 'csv'
image_list = CSV.read("jmeter/imagelist.csv")
CSV.open("image_details.csv", "w") do |csv|
  csv << ["OID", "info.json url"]
  image_list.each do |row|
    row << "https://collections.library.yale.edu/iiif/2/#{row[0]}/info.json"
    csv << row
    # need ptiff url from S3 with auth
    # utilize partridge gem 
    # s3://BUCKET_NAME/ptiffs/
    # https://BUCKET_NAME.s3.amazonaws.com/ptiffs/17/15/35/16/17/15351617.tif
  end
end
