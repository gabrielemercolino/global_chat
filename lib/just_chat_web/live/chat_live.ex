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

end
