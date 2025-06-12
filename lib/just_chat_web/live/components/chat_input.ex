defmodule JustChatWeb.Components.ChatInput do
  use Phoenix.Component

  attr :input, :string, required: true

  def chat_input(assigns) do
    ~H"""
    <div class="flex gap-2 z-50">
      <input
        id="message_input"
        phx-hook="InputHook"
        name="message"
        class="flex-grow border rounded px-3 py-2"
        value={@input}
        placeholder="Scrivi un messaggio..."
        autocomplete="off"
      />
      <button id="send_button" class="bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded">Invia</button>
    </div>
    """
  end
end
