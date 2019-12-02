defmodule MrHonyakuWeb.BotController do
  use MrHonyakuWeb, :controller

  def line_callback(conn, %{"events" => events}) do
    %{"message" => message } = List.first(events)
    %{"source" => source } = List.first(events)
    events = List.first(events)
    endpoint_uri = "https://api.line.me/v2/bot/message/reply"

    json_data =
    case message["type"] do
      "image" ->
        brain_url =  "https://ocr-devday19.linebrain.ai/v1/recognition"
        image_url = "https://api.line.me/v2/bot/message/#{message["id"]}/content"
        service_id = "wUjIzhWuLOsDMOU5GMJ2XdMYNCfukH7E"
        data = %{
                 imageURL: [image_url],
                 entrance: "detection",
                 scaling: false,
                 segments: false
               }
              |> Poison.encode!
        headers = %{
                    "Content-Type" => "application/json"
                    "X-ClovaOCR-Service-ID" => service_id,
                  }[
        json_data =
        case HTTPoison.post(brain_uri, data, headers) do
          {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
            IO.puts body
            data = Poison.decode!(data)
            words = data["words"]
            text = Enum.map(words, fn word -> word["text"] end)
            messages = Enum.map(text, fn raw_text ->
              %{
                raw: raw_text
                translated: translate(ja, en, raw_text)
              }
            end)
            |> Enum.map(fn texts ->
                [
                  %{
                    type: "text",
                    text: "元の文章："<>texts[:raw]
                  },
                  %{
                    type: "text",
                    text: "翻訳："<>texts[:translated]
                  }
                ]
                end)
            |> List.flatten()
            %{replyToken: events["replyToken"],
                messages: messages
            } |> Poison.encode!

          {:ok, %HTTPoison.Response{status_code: 404}} ->
            IO.puts "Not found :("
            %{replyToken: events["replyToken"],
                messages: [
                  %{
                  type: "text",
                  text: "エラーが発生しました。もう一度試してください！" # 受信したメッセージをそのまま返す
                  }
                ]
            } |> Poison.encode!
          {:error, %HTTPoison.Error{reason: reason}} ->
            IO.inspect reason
            %{replyToken: events["replyToken"],
                messages: [
                  %{
                  type: "text",
                  text: "エラーが発生しました。もう一度試してください！" # 受信したメッセージをそのまま返す
                  }
                ]
            } |> Poison.encode!
        end

      _ ->%{
            replyToken: events["replyToken"],
            messages: [
              %{
              type: "text",
              text: "画像を送ってね！" # 受信したメッセージをそのまま返す
              }
            ]
          } |> Poison.encode!
    end

    headers = %{
      "Content-Type" => "application/json",
      "Authorization" => "Bearer ${7qco1iW1oMODOe/GL9HtBqxxaPvayqwpnABfUJ7pgYlp0yCCX6gyAHLwQhIRXk9Yyu2wGMguVX7JmaKjlf9DiAQHF2xtbWbpf35DcR1HSQY/gTBozEyw0IPZMdvWjERc9NuSjvVffB6JxF7URfYkZwdB04t89/1O/w1cDnyilFU=}"   #メッセージ送受信設定|>アクセストークンからアクセストークンを取得
    }

    case HTTPoison.post(endpoint_uri, json_data, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        IO.puts body
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        IO.puts "Not found :("
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect reason
    end

    send_resp(conn, :no_content, "")
  end

  def translate(source, target, text) do
    url = "https://script.google.com/macros/s/AKfycbztT9dreJnvkAQclPEONs27RwkKGdUt7dKDitIRQ08ppJeNt5Bm/exec?text=#{text}&source=#{source}&target=#{target}"
    case HTTPoison.get(url) do
      {:ok, response} -> translated_text = Poison.decode(response)
                         translated_text["text"]
      {:error, reason} -> {:error, reason}
    end
  end
end
