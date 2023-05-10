# Check if todo.md exists, if not, create it
if [ ! -f todo.md ]; then
  touch todo.md
fi
# Prompt user for input and append it to todo.md
while true; do
    
    cat todo.md
    echo "Enter a new todo item (or type 'list' to view the todo list):"
    read todo_item
    if [ "$todo_item" = "list" ]; then
        # Use less to view and navigate the todo list
        stdbuf -o0 cat todo.md 
    else
        echo "- [ ] $todo_item" >> todo.md
        # Display the updated todo list
        echo "Updated todo list:"
        cat todo.md
    fi
done

