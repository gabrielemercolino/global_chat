defmodule JustChatWeb.ChatLive do
  import JustChatWeb.Components.{RoomModal, Header, ChatInput}
  import JustChat.Rooms, only: [validate_room_name: 1]

  use JustChatWeb, :live_view
  alias Phoenix.PubSub

  # Mount for /channel/:id
  def mount(%{"id" => id}, _session, socket) do
    mount_room(id, socket)
  end

  # Mount for /
  def mount(_params, _session, socket) do
    mount_room("global", socket)
  end

  defp mount_room(id, socket) do
    channel = "room:#{id}"
    socket_id = System.system_time(:nanosecond)

    PubSub.subscribe(JustChat.PubSub, channel)

    {
      :ok,
      socket
      |> assign(id: id, socket_id: socket_id, channel: channel)
      |> assign(modal_error: nil, show_modal: false)
      |> assign(input: "")
      |> stream(:messages, [])
    }
  end

  def handle_event("open_room_modal", _, socket) do
    socket = socket |> assign(show_modal: true)

    {:noreply, socket}
  end

  def handle_event("close_room_modal", _, socket) do
    socket = socket |> assign(show_modal: false)

    {:noreply, socket}
  end

  def handle_event("validate_room", %{"room" => room}, socket) do
    error =
      room
      |> String.trim()
      |> validate_room_name()
      |> room_error_message()

    {:noreply, assign(socket, modal_error: error)}
  end

  def handle_event("change_room", %{"room" => room}, socket) do
    room = String.trim(room || "")

    case validate_room_name(room) do
      :ok ->
        {:noreply, push_navigate(socket, to: ~p"/channel/#{room}", replace: true)}
      error ->
        {:noreply, assign(socket, modal_error: room_error_message(error))}
    end
  end

  def handle_event("send_msg", %{"message" => ""}, socket) do
    {:noreply, socket}
  end

  def handle_event("send_msg", %{"message" => msg}, socket) do
    channel = socket.assigns.channel
    sender_id = socket.assigns.socket_id
    now = DateTime.utc_now()

    PubSub.broadcast(JustChat.PubSub, channel, {:new_msg, msg, sender_id, now})

    {:noreply, socket}
  end

  def handle_info({:new_msg, msg, sender_id, time}, socket) do
    from_self = sender_id == socket.assigns.socket_id

    new_msg = %{from_self: from_self, body: msg, time: time, id: time}

    socket = socket |> stream_insert(:messages, new_msg)
    {:noreply, socket}
  end

  defp room_error_message(:ok), do: nil
  defp room_error_message(:empty), do: "Channel name can't be empty"
  defp room_error_message(:too_long), do: "Channel name can't be more than 30 characters long"
  defp room_error_message(:invalid_characters), do: "Channel name can only contain letters, numbers, - or _"
  defp room_error_message(_), do: "An unknown error occurred"

  defp linkify(text) do
    # Regex matches:
    # - URLs starting with http:// or https://
    # - URLs starting with www.
    # - Domain names with a TLD (e.g., example.com)
    # Captures query parameters and fragments (e.g., ?query=param#fragment)
    # Also captures trailing punctuation like ., !, ?, ;, etc. so they can be preserved
    # and not included in the link.
    link_regex =
    ~r/((https?:\/\/|www\.)[a-zA-Z0-9\-\._~:\/\?#\[\]@!\$&'\(\)\*\+,;=%]+|\b[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(?:\/[a-zA-Z0-9\-\._~:\/\?#\[\]@!\$&'\(\)\*\+,;=%]*)?)([.,!?:;\)\]\}]*)/

    # Regex matches @mentions of rooms, allowing alphanumeric characters, underscores, and hyphens
    room_regex = ~r/@([A-Za-z0-9_-]{1,30})/

    text
    |> html_escape()
    |> safe_to_string()

    text = Regex.replace(link_regex, text, fn _full, url, _scheme, trailing ->
      href =
        cond do
          String.starts_with?(url, "http://") or String.starts_with?(url, "https://") ->
            url
          true ->
            "https://" <> url
        end


      ~s(<a href="#{href}" target="_blank" rel="noopener noreferrer" class="text-blue-600 underline">#{url}</a>#{trailing})
    end)

    Regex.replace(room_regex, text, fn _full, room ->
      ~s(<a href="/channel/#{room}" phx-link="redirect" phx-link-state="push" class="text-blue-600 underline">@#{room}</a>)
    end)
  end
end
