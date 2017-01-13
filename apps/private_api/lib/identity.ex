defmodule InstaCrawler.PrivateAPI.Identity do
  import ExPrintf

  def create_random do
    user_agent = generate_random_user_agent
    guid = generate_guid
    device_id = generate_device_id(guid)

    %{user_agent: user_agent, guid: guid, device_id: device_id}
  end

  defp generate_random_user_agent do
    resolution = ['720x1280', '320x480', '480x800', '1024x768', '1280x720', '768x1024', '480x320'] |> Enum.random

    version = ['GT-N7000', 'SM-N9000', 'GT-I9220', 'GT-I9100'] |> Enum.random
    dpi = ['120', '160', '320', '240'] |> Enum.random

    "Instagram 10.3.2 Android (18/4.3; #{dpi}; #{resolution}; samsung; #{version}; #{version}; smdkc210; en_US)"
  end

  defp generate_guid do
    random_vals = [
                    Enum.random(0..65535),
                    Enum.random(0..65535),
                    Enum.random(0..65535),
                    Enum.random(16384..20479),
                    Enum.random(32768..49151),
                    Enum.random(0..65535),
                    Enum.random(0..65535),
                    Enum.random(0..65535)
                  ]

    sprintf("%04x%04x-%04x-%04x-%04x-%04x%04x%04x", random_vals)
  end

  defp generate_device_id(guid) do
    "android-#{guid}"
  end
end
