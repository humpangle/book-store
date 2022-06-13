defmodule BookStore.ManningBookScraper do
  @manning_host "www.manning.com"

  @url "https://#{@manning_host}/catalog"

  @poison_opts [
    timeout: :timer.seconds(1_000),
    recv_timeout: :timer.seconds(1_000)
  ]

  def get_manning_books() do
    get_manning_catalog_page()
    |> get_book_links_from_page()
    |> Task.async_stream(
      &get_book_details/1,
      timeout: :timer.seconds(1_000)
    )
    |> Enum.map(fn {:ok, book_details} -> book_details end)
    |> Jason.encode!()
    |> then(
      &File.write!(
        data_file_location(),
        &1
      )
    )
  end

  def data_file_location, do: "./books_data.exs"

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

  defp get_book_details(book_url) do
    HTTPoison.get!(book_url, @poison_opts).body
    |> Floki.parse_document!()
    |> then(
      &%{
        title: get_book_title(&1),
        authors: get_book_author(&1),
        description: get_book_description(&1),
        prices: get_book_prices(&1)
      }
    )
  end

  defp get_book_prices(parsed_page),
    do:
      parsed_page
      |> Floki.find(".prices > .price")
      |> Floki.text(deep: false)
      |> String.split()
      |> Enum.map(&String.trim/1)
      |> Enum.reject(fn price -> price == "$0.00" || price == "FREE" end)
      |> then(&if &1 == [], do: :not_for_sale, else: &1)

  defp get_book_description(parsed_page),
    do:
      parsed_page
      |> Floki.find("[name*='about-the-book']+p")
      |> Floki.text(deep: false)
      |> String.trim()

  defp get_book_author(parsed_page),
    do:
      parsed_page
      |> Floki.find(".product-authors")
      |> Floki.text(deep: false)
      |> String.split([",", "and"])
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&Kernel.==(&1, ""))

  defp get_book_title(parsed_page),
    do:
      parsed_page
      |> Floki.find(".product-title")
      |> Floki.text(deep: false)
      |> String.trim()
end
