defmodule StowlyWeb.BackupController do
  use StowlyWeb, :controller

  def download(conn, %{"path" => path, "filename" => filename}) do
    if File.exists?(path) and String.starts_with?(path, System.tmp_dir!()) do
      conn
      |> put_resp_content_type("application/gzip")
      |> put_resp_header("content-disposition", ~s(attachment; filename="#{filename}"))
      |> send_file(200, path)
    else
      conn
      |> put_status(404)
      |> text("File not found")
    end
  end
end
