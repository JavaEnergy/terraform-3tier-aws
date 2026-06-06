project_name = "myapp"
environment  = "dev"

# ─── MONITORING ─────────────────────────────────────────────────────────────
alert_email         = "chogovadzebeka@gmail.com"
cpu_alarm_threshold = 80

# ─── DATABASE ───────────────────────────────────────────────────────────────
db_name           = "appdb"
db_username       = "appuser"
db_instance_class = "db.t3.micro"
multi_az          = false

# ─── ECS ────────────────────────────────────────────────────────────────────
ecs_cpu           = 256
ecs_memory        = 512
ecs_desired_count = 1
container_port    = 5000

# ─── CONTAINER IMAGES ────────────────────────────────────────────────────────
# Update these AFTER running: ./app/build_and_push.sh
# Example: primary_container_image = "123456789.dkr.ecr.us-east-1.amazonaws.com/myapp-dev:latest"
primary_container_image   = "public.ecr.aws/nginx/nginx:latest"
secondary_container_image = "public.ecr.aws/nginx/nginx:latest"
