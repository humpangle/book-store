defmodule BookStore.ManningBookScraper do
  @url "https://www.manning.com/catalog"

  @poison_opts [
    timeout: :timer.seconds(100),
    recv_timeout: :timer.seconds(100)
  ]

  def get_manning_books() do
    get_manning_catalog_page()
  end

  defp get_manning_catalog_page,
    do: HTTPoison.get!(@url, [], @poison_opts).body
end
