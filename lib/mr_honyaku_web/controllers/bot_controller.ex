defmodule MrHonyakuWeb.BotController do
  use MrHonyakuWeb, :controller

  def line_callback(conn, %{"events" => events}) do
    %{"message" => message } = List.first(events)
    %{"source" => source } = List.first(events)
    events = List.first(events)
    endpoint_uri = "https://api.line.me/v2/bot/message/reply"
    line_auth_token = Application.get_env(:mr_honyaku, :line_auth_token)

    json_data =
    case message["type"] do
      "image" ->
        image_url = "https://api.line.me/v2/bot/message/#{message["id"]}/content"
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
            raw_text = Enum.join(text)
            messages =
              case translate("en", "ja", raw_text) do
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

      _ ->%{
            replyToken: events["replyToken"],
            messages: [
              %{
              type: "text",
              text: "画像を送ってね！"
              }
            ]
          } |> Poison.encode!
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
