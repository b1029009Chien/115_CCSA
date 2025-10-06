import pytest
from flask import Flask
from application import app as flask_app

@pytest.fixture
def client():
    flask_app.config['TESTING'] = True
    with flask_app.test_client() as client:
        yield client

def test_health(client):
    resp = client.get('/api/health')
    assert resp.status_code == 200
    assert resp.get_json()['ok'] is True

def test_add_and_list_and_delete_name(client):
    # 新增
    resp = client.post('/api/names', json={"name": "Alice"})
    assert resp.status_code == 201
    data = resp.get_json()
    assert data['name'] == 'Alice'
    name_id = data['id']

    # 查詢
    resp = client.get('/api/names')
    assert resp.status_code == 200
    names = resp.get_json()
    assert any(n['name'] == 'Alice' for n in names)

    # 刪除
    resp = client.delete(f'/api/names/{name_id}')
    assert resp.status_code == 204

    # 再查詢，應該找不到 Alice
    resp = client.get('/api/names')
    assert resp.status_code == 200
    names = resp.get_json()
    assert not any(n['name'] == 'Alice' for n in names)

def test_add_name_empty(client):
    resp = client.post('/api/names', json={"name": ""})
    assert resp.status_code == 400
    assert 'error' in resp.get_json()

def test_add_name_too_long(client):
    resp = client.post('/api/names', json={"name": "A"*51})
    assert resp.status_code == 400
    assert 'error' in resp.get_json()

def test_delete_not_found(client):
    resp = client.delete('/api/names/999999')
    assert resp.status_code == 404
    assert 'error' in resp.get_json()
