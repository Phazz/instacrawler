defmodule InstaCrawler.PrivateAPI.Crypto do

  @key "5ad7d6f013666cc93c88fc8af940348bd067b68f0dce3c85122a923f4f74b251"

  def sign_body(data) do
    signature = sign(data)
    data = URI.encode(data, &(URI.char_unreserved?/1))
    "ig_sig_key_version=4&signed_body=#{signature}.#{data}"
  end

  defp sign(data) do
    :crypto.hmac(:sha256, @key, data) |> Base.encode16 |> String.downcase
  end
end
