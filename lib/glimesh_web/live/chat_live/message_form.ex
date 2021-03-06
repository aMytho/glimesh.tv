defmodule GlimeshWeb.ChatLive.MessageForm do
  use GlimeshWeb, :live_component

  import Appsignal.Phoenix.LiveView, only: [instrument: 4]

  alias Glimesh.Chat

  @impl true
  def update(%{chat_message: chat_message, user: user, channel: channel} = assigns, socket) do
    changeset = Chat.change_chat_message(chat_message)

    include_animated = if user, do: Glimesh.Payments.has_platform_subscription?(user), else: false

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign(
       :emotes,
       Glimesh.Emote.list_emotes_for_js(include_animated)
     )
     |> assign(:channel_username, channel.user.username)
     |> assign(:disabled, is_nil(user))}
  end

  @impl true
  def handle_event("send", %{"chat_message" => chat_message_params}, socket) do
    instrument(__MODULE__, "send", socket, fn ->
      # Pull a fresh user and channel from the database in case something has changed
      user = Glimesh.Accounts.get_user!(socket.assigns.user.id)
      channel = Glimesh.ChannelLookups.get_channel!(socket.assigns.channel.id)
      save_chat_message(socket, channel, user, chat_message_params)
    end)
  end

  defp save_chat_message(socket, channel, user, chat_message_params) do
    case Chat.create_chat_message(user, channel, chat_message_params) do
      {:ok, _chat_message} ->
        {:noreply,
         socket
         |> assign(:changeset, Chat.empty_chat_message())}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}

      # Permissions errors
      {:error, error_message} ->
        error_changeset = %Ecto.Changeset{
          action: :validate,
          changes: chat_message_params,
          errors: [
            message: {error_message, [validation: :required]}
          ],
          data: %Glimesh.Chat.ChatMessage{},
          valid?: false
        }

        {:noreply, assign(socket, changeset: error_changeset)}
    end
  end
end
