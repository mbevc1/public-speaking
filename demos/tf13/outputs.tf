output "a_pet" {
  value = random_pet.pet.id
}

output "buckets1" {
  value = module.buckets1
}

output "buckets2" {
  value = module.buckets2
}

#output "test" {
#  value = module.test.o
#}
#
#output "f_name2" {
#  value = module.f["name2"].o
#}
#
#output "c" {
#  value = module.c
#}
