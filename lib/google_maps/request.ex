defmodule GoogleMaps.Request do
  @moduledoc false

  @doc """
  GET an endpoint with param keyword list
  """
  @spec get(String.t, keyword()) :: GoogleMaps.Response.t
  def get(endpoint, params) do
    {secure, params} = Keyword.pop(params, :secure, true)
    {key, params} = Keyword.pop(params, :key, api_key())
    {headers, params} = Keyword.pop(params, :headers, [])
    {options, params} = Keyword.pop(params, :options, [])

    query =
      (if secure, do: Keyword.put(params, :key, key), else: params)
      |> Enum.map(&transform_param/1)
      |> URI.encode_query()

    scheme = if secure, do: "https", else: "http"
    url = "#{scheme}://maps.googleapis.com/maps/api/#{endpoint}/json"

    requester().get("#{url}?#{query}", headers, options)
  end

  # Helpers

  defp api_key do
    Application.get_env(:google_maps, :api_key) ||
      System.get_env("GOOGLE_MAPS_API_KEY")
  end

  defp requester do
    Application.get_env(:google_maps, :requester)
  end

  defp transform_param({type, {lat, lng}})
  when type in [:origin, :destination]
  and is_number(lat)
  and is_number(lng)
  do
    {type, "#{lat},#{lng}"}
  end

  defp transform_param({type, {:place_id, place_id}})
  when type in [:origin, :destination]
  do
    {type, "place_id:#{place_id}"}
  end

  defp transform_param({:waypoints, "enc:" <> enc}) do
    {:waypoints, "enc:" <> enc}
  end

  defp transform_param({:waypoints, waypoints})
  when is_list(waypoints) do
    transform_param({:waypoints, Enum.join(waypoints, "|")})
  end

  defp transform_param({:waypoints, waypoints}) do
    # @TODO: Encode the waypoints into encoded polyline.
    {:waypoints, "optimize:true|#{waypoints}"}
  end

  defp transform_param(param), do: param
end