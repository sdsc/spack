#!/bin/bash

isdigit ()    # Tests whether *entire string* is numerical.
{             # In other words, tests for integer variable.
  [ $# -eq 1 ] || returna 9;
  case $1 in
    *[!0-9]*|"") return 9;;
              *) return 0;;
  esac
}

function register_by_userinfo
{
    with_ordernum=0
    while [ true ]; do
      echo
      echo "  -----------------------------"
      echo                                                                                       
      echo "  Q-Chem User Registration:"
      echo "  [IMPORTANT: a valid Email entered below is REQUIRED to receive license]"
      echo                                                                                        
      echo "  Type your information and press <Enter> "
      echo
      printf " Name:"                                                                      
      read with_username
      printf " Department/Group:"
      read with_group
      printf " GroupLeader:"
      read with_groupleader
      printf " Institute/Company:"
      read with_company
      printf " EMAIL:"
      read with_email
      echo
      echo "  -----------------------------"

      echo
      echo "  User Registraton Information:"
      echo "  -----------------------------"
      echo "  Order Number: ${with_ordernum}"
      echo "  User Name:    ${with_username}"
      echo "  Department:   ${with_group}"
      echo "  GroupLeader:  ${with_groupleader}"
      echo "  Institute:    ${with_company}"
      echo "  Email:        ${with_email}"
      echo

      local confirm
      while [ true ]; do
         printf "  Is the above information correct?<y/n>...<y>"
         read confirm
         if [ "x$confirm" == "xy" -o  "x$confirm" == "x" ] ; then break; fi
         if [ "x$confirm" == "xn" ] ; then break; fi
      done
      if [ "x$confirm" == "xy" -o  "x$confirm" == "x" ] ; then break; fi
    done
    echo "  Thank you for your registration!  "
    echo 
} 

function register_by_order_number
{
   clear
#  print_msg_get_ordernum
   cat << ENDOF_GET_ORDER_NUM

******************************************************************
*                                                                *
*                  Q-Chem License Registration                   *
*                                                                *
******************************************************************

Registration is required for licensing purpose and a VALID Email 
address must be provided to receive Q-Chem license file. 

 - If you are a current Q-Chem user please provide the order number 
   below. It can be found in the email you received from Q-Chem.

 - If you are a new Q-Chem user without order nubmer please enter 0
   below and provide the registration information subsequently.

ENDOF_GET_ORDER_NUM

#
#- get old order number
#
   local ordnum=0
   local ordfound
#  while [ true ] ; do
#     ordfound=false
#     printf "  Please enter your order number: "
#     read ordnum leftover
#     if [ "x$ordnum" == "x" ] ; then continue; fi
#     isdigit "$ordnum"
#     if [ $? -ne 0 ] ; then
#        echo "  The order number $ordernum you entered has format error"
#        continue
#     fi
#     if [ "x$ordnum" == "x0" ] ; then break; fi
#     if [ $ordnum -le 1000 -o $ordnum -ge 7200 ] ; then
#        echo "  The order number $ordernum you entered is not valid"
#        continue
#     fi
#     ordfound=true
#     with_ordernum=$ordnum
#
#     echo
#     echo    "  [IMPORTANT: a valid Email is REQUIRED to receive license]"
#     printf  "  Please enter your email address CORRECTLY: "
#     read with_email
#
#     echo
#     echo "  User Registraton Information:"
#     echo "  -----------------------------"
#     echo "  Order Number: ${with_ordernum}"
#     echo "  Email:        ${with_email}"
#     echo
#
#     local confirm
#     while [ true ]; do
#        printf "  Is the above information correct?<y/n>...<y>"
#        read confirm
#        if [ "x$confirm" == "xy" -o  "x$confirm" == "x" ] ; then break; fi
#        if [ "x$confirm" == "xn" ] ; then break; fi
#     done
#     if [ "x$confirm" == "xy" -o  "x$confirm" == "x" ] ; then break; fi
#  done
#
#  if [ $ordfound == "true" ] ; then 
#     echo 
#     echo "  Thank you for your registration!  "
#     echo
#     return 0
#  else 
#     return 9
#  fi
}

function register_qchem
{
   register_by_order_number
   if [ $? != 0 ] ; then
      register_by_userinfo
   fi
   regiinfo+=("Order Number: ${with_ordernum}   ")
   regiinfo+=("User Name:    ${with_username}   ")
   regiinfo+=("Department:   ${with_group}      ")
   regiinfo+=("GroupLeader:  ${with_groupleader}")
   regiinfo+=("Institute:    ${with_company}    ")
   regiinfo+=("Email:        ${with_email}      ")
}

#register_qchem

