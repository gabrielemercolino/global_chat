defmodule GlobalChatWeb.Components.RoomModal do
  use Phoenix.Component

  attr :error, :string
  attr :id, :string, default: "room_modal"

  def room_modal(assigns) do
    ~H"""
    <div class="fixed inset-0 bg-black/40 flex justify-center items-center z-50">
      <div class="bg-white p-6 rounded shadow-md w-80">
        <h2 class="text-lg font-bold mb-4">Cambia canale</h2>
        <.form for={%{}} as={:room} phx-submit="change_room" phx-change="validate_room">
          <input name="room" type="text" class="border px-2 py-1 w-full mb-4" placeholder="Nome canale" />
          <div class="flex justify-end gap-2">
            <%= if @error do %>
              <p class="text-red-600 text-sm mt-1"><%= @error %></p>
            <% end %>
            <button type="button" phx-click="close_room_modal" class="text-sm text-gray-600">Annulla</button>
            <button type="submit" class={[
                "text-white px-3 py-1 rounded text-sm",
                @error != nil && "bg-red-500 cursor-not-allowed disabled",
                @error == nil && "bg-blue-500 hover:bg-blue-600"
              ]}>Vai</button>
          </div>
        </.form>
      </div>
    </div>
    """
  end
end
