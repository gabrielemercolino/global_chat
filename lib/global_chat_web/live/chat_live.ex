defmodule GlobalChatWeb.ChatLive do
  import GlobalChatWeb.Components.{RoomModal, Header, ChatInput}
  import GlobalChat.Rooms, only: [validate_room_name: 1]

  use GlobalChatWeb, :live_view
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

    PubSub.subscribe(GlobalChat.PubSub, channel)

    {
      :ok,
      socket
      |> assign(id: id, socket_id: socket_id, channel: channel)
      |> assign(modal_error: nil, show_modal: false)
      |> assign(input: "", messages: [])
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

    error = case error do
      :ok -> nil
      :empty -> "Il nome del canale non può essere vuoto."
      :too_long -> "Il nome del canale non può superare i 30 caratteri."
      :invalid_characters -> "Il nome del canale può contenere solo lettere, numeri, - e _."
    end

    {:noreply, assign(socket, modal_error: error)}
  end

  def handle_event("change_room", %{"room" => room}, socket) do
    room = String.trim(room || "")

    case validate_room_name(room) do
      :ok ->
        {:noreply, push_navigate(socket, to: ~p"/channel/#{room}", replace: true)}

      :empty ->
        {:noreply, assign(socket, modal_error: "Il nome del canale non può essere vuoto.")}
      :too_long ->
        {:noreply, assign(socket, modal_error: "Il nome del canale non può superare i 30 caratteri.")}
      :invalid_characters ->
        {:noreply, assign(socket, modal_error: "Il nome del canale può contenere solo lettere, numeri, - e _.")}
    end


  end

  def handle_event("send_msg", %{"message" => ""}, socket) do
    {:noreply, socket}
  end

  def handle_event("send_msg", %{"message" => msg}, socket) do
    channel = socket.assigns.channel
    sender_id = socket.assigns.socket_id
    now = DateTime.utc_now() |> Calendar.strftime("%H:%M %Z")

    PubSub.broadcast(GlobalChat.PubSub, channel, {:new_msg, msg, sender_id, now})

    {:noreply, socket}
  end

  def handle_info({:new_msg, msg, sender_id, time}, socket) do
    from_self = sender_id == socket.assigns.socket_id

    new_msg = %{from_self: from_self, body: msg, time: time}
    messages = socket.assigns.messages ++ [new_msg]

    socket = socket |> assign(:messages, messages)

    {:noreply, socket}
  end
end
