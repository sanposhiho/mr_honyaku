defmodule MrHonyakuWeb.BotController do
  use MrHonyakuWeb, :controller

  def line_callback(conn, %{"events" => events}) do
    IO.inspect events
    event_contents = List.first(events)
    message = Map.get(event_contents, "message")
    type = if is_nil(message), do: nil, else: message["type"]
    events = List.first(events)
    endpoint_uri = "https://api.line.me/v2/bot/message/reply"
    line_auth_token = Application.get_env(:mr_honyaku, :line_auth_token)

    json_data =
    case type do
      "image" ->
        message_id = message["id"]
        %{"replyToken" => events["replyToken"],
          "messages" =>
          [%{
            "type" => "flex",
            "altText" => "言語を選択してください。",
            "contents" => %{
            "type" => "bubble",
            "body" => %{
              "type" => "box",
              "layout" => "vertical",
              "spacing" => "md",
              "contents" => [
                %{
                  "type" => "button",
                  "style" => "secondary",
                  "action" => %{
                    "type" => "postback",
                    "label" => "日本語→英語",
                    "displayText" => "日本語を英語に翻訳",
                    "data" => "en&"<>message_id
                  }
                },
                %{
                  "type" => "button",
                  "style" => "secondary",
                  "action" => %{
                    "type" => "postback",
                    "label" => "英語→日本語",
                    "displayText" => "英語を日本語に翻訳",
                    "data" => "ja&"<>message_id
                  }
                }
              ]
            }
            }}]}|>Poison.encode!
      _ ->
        if Map.has_key?(event_contents, "postback") do
        reply_contents = event_contents["postback"]["data"]
        target = String.slice(reply_contents, 0..1)
        message_id = String.slice(reply_contents, 3..-1)
        image_url = "https://api.line.me/v2/bot/message/#{message_id}/content"
        header = %{"Authorization" => "Bearer ${#{line_auth_token}}"}
        %HTTPoison.Response{body: body} = HTTPoison.get!(image_url, header)
        image = body |> Base.encode64()
        brain_url =  "https://ocr-devday19.linebrain.ai/v1/recognition"
        service_id = Application.get_env(:mr_honyaku, :brain_service_id)
        data = %{
          imageContent: [image],
                 entrance: "detection",
                 scaling: false,
                 segments: false
               }
              |> Poison.encode!
        headers = %{
                    "X-ClovaOCR-Service-ID" => service_id,
                    "Content-Type" => "application/json"
                  }
        case HTTPoison.post(brain_url, data, headers) do
          {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
            IO.puts body
            image_data = Poison.decode!(body)
            words = image_data["words"]
            text = Enum.map(words, fn word -> word["text"] end)
            raw_text = Enum.join(text, " ")
            messages =
              case translate("hoge", target, raw_text) do
                {:ok, translated} ->
                  %{
                    raw: raw_text,
                    translated: translated
                  }
                _ ->
                  %{
                    raw: raw_text,
                    translated: "エラーが発生しました。。"
                  }
              end
            messages_list=
            [
              %{
                type: "text",
                text: "原文："<>messages[:raw]
              },
              %{
                type: "text",
                text: "翻訳："<>messages[:translated]
              }
            ]
            |> List.flatten()
            %{replyToken: events["replyToken"],
                messages: messages_list
            } |> Poison.encode!

          error ->
            IO.inspect error
            %{replyToken: events["replyToken"],
                messages: [
                  %{
                  type: "text",
                  text: "エラーが発生しました。もう一度試してください！"
                  }
                ]
            } |> Poison.encode!
        end

      else
        %{
            replyToken: events["replyToken"],
            messages: [
              %{
              type: "text",
              text: "画像を送ってね！"
              }
            ]
          } |> Poison.encode!
      end
    end

    headers = %{
      "Content-Type" => "application/json",
      "Authorization" => "Bearer ${#{line_auth_token}}"
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
    url = "https://mr-honyaku.cognitiveservices.azure.com/sts/v1.0/issuetoken"
    translation_auth = Application.get_env(:mr_honyaku, :translation_auth)
    headers = %{"Ocp-Apim-Subscription-Key" => translation_auth }
    with %HTTPoison.Response{status_code: 200, body: body} <- HTTPoison.post!(url, [], headers) do
      IO.puts body
      token = "Bearer "<>body
      transrate_url = "https://api.cognitive.microsofttranslator.com/translate?api-version=3.0&to=#{target}"
      headers = %{
        "Authorization" => token,
        "Content-Type" => "application/json; charset=UTF-8",
        "Content-Length" => String.length(text)
      }
      json = [%{
        "text" => text,
      }]|>Poison.encode!
      case HTTPoison.post(transrate_url, json, headers) do
        {:ok,%HTTPoison.Response{status_code: 200, body: body}}->
          IO.inspect body
          body = body |> Poison.decode!|>Enum.at(0)
          translations = body["translations"]|>Enum.at(0)
          {:ok, translations["text"]}
        error ->
          IO.inspect error
          {:error, error}
      end

    else
      error -> IO.inspect error
        {:error, error}
    end
  end
end
