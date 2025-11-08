```
udo KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl get nodes
NAME                            STATUS   ROLES                  AGE     VERSION
chien-vmware-virtual-platform   Ready    control-plane,master   6h22m   v1.33.5+k3s1
isl3080                         Ready    <none>                 5h26m   v1.33.5+k3s1
```

```
sudo KUBECONFIG=/etc/ranch
er/k3s/k3s.yaml kubectl -n hw6 get pods -o wide
NAME                   READY   STATUS      RESTARTS   AGE     IP           NODE                            NOMINATED NODE   READINESS GATES
api-7c64dbd9cc-krqwv   1/1     Running     0          5m14s   10.42.0.42   chien-vmware-virtual-platform   <none>           <none>

db-85d7cfcc4c-r2962    1/1     Running     0          25m     10.42.1.13   isl3080                         <none>           <none>

web-bb746f498-fsfdk    1/1     Running     0          9m50s   10.42.0.41   chien-vmware-virtual-platform   <none>           <none>
```

```
curl -sS http://192.168.0.36/api/names 2>&1
[{"created_at":"Sat, 08 Nov 2025 15:11:45 GMT","id":1,"name":"11"}]
``````

```
curl -sS -X DELETE http://192.168.0.36/api/names/1
curl -sS http://192.168.0.36/api/names 2>&1
[]
curl -sS -X POST http://192.168.0.36/api/names \
  -H 'Content-Type: application/json' \
  -d '{"name":"Alice"}'
{"created_at":"Sat, 08 Nov 2025 15:19:40 GMT","id":2,"name":"Alice"}
```

```
curl -sS http://192.168.0.36/api/health 2>&1
{"ok":true}
```

```
kubectl -n hw6 rollout restart deployment db
kubectl -n hw6 rollout status deployment db
deployment.apps/db restarted
Waiting for deployment "db" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "db" rollout to finish: 1 old replicas are pending termination...
deployment "db" successfully rolled out

curl -sS http://192.168.0.36/api/names 2>&1
[{"created_at":"Sat, 08 Nov 2025 15:19:40 GMT","id":2,"name":"Alice"}]
```