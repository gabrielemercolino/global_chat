defmodule GlobalChatWeb.Components.Header do
  use Phoenix.Component

  attr :version, :string, required: true
  attr :repo_link, :string, required: true
  attr :channel, :string, required: true

  def top_bar(assigns) do
    ~H"""
    <header class="fixed top-0 left-0 right-0 px-4 sm:px-6 lg:px-8 z-100 bg-white">
      <div class="flex items-center justify-between border-b border-zinc-100 py-3 text-sm">
        <p class="bg-brand/5 text-brand rounded-full px-2 font-medium leading-6">
          v{@version}
        </p>

        <div phx-click="open_room_modal" class="cursor-pointer text-blue-600">
          {@channel}
        </div>

        <div class="flex items-center gap-4 font-semibold leading-6 text-zinc-900">
          <a href="https://github.com/gabrielemercolino/global_chat" class="hover:text-zinc-700">
            GitHub
          </a>
        </div>
      </div>
    </header>
    """
  end
end
