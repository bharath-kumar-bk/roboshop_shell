
#!/bin/bash


#Create 01_arguments.sh: to get informsation about argumenats 
echo "Script name: $0"
echo "First argument: $1"
echo "Second argument: $2"
echo "All arguments: $@"
echo "Number of arguments: $#"
# exit status 
echo "Hello DevOps"
echo "Exit status: $?"

ls /folder_does_not_exist
echo "Exit status: $?"
#Example 3: Process IDs using $$ and $!
echo "Hello DevOps"
echo "Exit status: $?"

ls /folder_does_not_exist
echo "Exit status: $?"
Example 4: User and directory variables
echo "Username: $USER"
echo "Home directory: $HOME"
echo "Current directory: $PWD"
echo "Previous directory: $OLDPWD"
echo "Bash version: $BASH_VERSION"
echo "Hostname: $HOSTNAME"