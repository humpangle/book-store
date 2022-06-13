defmodule BookStore.ManningBookScraper do
  @manning_host "www.manning.com"
  @url "https://#{@manning_host}/catalog"

  @poison_opts [
    timeout: :timer.seconds(100),
    recv_timeout: :timer.seconds(100)
  ]

  def get_manning_books() do
    get_manning_catalog_page()
    |> get_book_links_from_page()
  end

  defp get_manning_catalog_page,
    do: HTTPoison.get!(@url, [], @poison_opts).body

  defp get_book_links_from_page(page_source) do
    page_source
    |> Floki.parse_document!()
    |> Floki.find("a.catalog-link")
    |> Enum.map(
      &URI.to_string(%URI{
        path: Floki.attribute(&1, "href"),
        host: @manning_host,
        scheme: "https"
      })
    )
  end
end
