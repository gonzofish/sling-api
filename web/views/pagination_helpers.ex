defmodule Sling.PaginationHelpers do
  def pagination(page) do
    %{
      page_number: page.page_number,
      page_size: page.page_size,
      total_entries: page.total_entries,
      total_pages: page.total_pages
    }
  end
end