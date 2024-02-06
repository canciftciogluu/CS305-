//
//  main.cpp
//  PA4*CS307
//
//  Created by Can Ciftcioglu on 30.05.2023.
//

#include <iostream>
#include <mutex>

using namespace std;

struct Node {
    int id;
    int size;
    int idx;
    Node* prev;
    Node* next;
};

class HeapManager {
private:
    Node* head;

public:
    mutex mtx;
    
    int initHeap(int size) {
        Node *newNode = new Node;
        newNode->id = -1;
        newNode->size = size;
        newNode->idx = 0;
        newNode->next = NULL;
        newNode->prev = NULL;
        head = newNode;
        print();
        return 1;
    }
    
    int myMalloc(int ID, int size) {
        mtx.lock();
        Node *current = head;
        bool allocated = false;
        int index = -1;
        
        while (current != NULL && !allocated) {
            if (current->id == -1 && current->size > size) {
                Node *newNode = new Node;
                newNode->size = size;
                newNode->id = ID;
                newNode->idx = current->idx;
                current->idx += size;
                current->size -= size;
                newNode->next = current;
                newNode->prev = current->prev;
                if (current->prev) current->prev->next = newNode;
                current->prev = newNode;
                if (current == head) head = newNode;
                index = newNode->idx;
                allocated = true;
            }
            current = current->next;
        }

        if (allocated) {
            cout << "Allocated for thread " << ID << endl;
            print();
        }
        mtx.unlock();
        return index;
    }
    
    int myFree(int ID, int index) {
        mtx.lock();
        bool deallocated = false;
        Node* current = head;
        auto mergeNodes = [](Node* a, Node* b) {
            a->size += b->size;
            a->next = b->next;
            if (b->next) b->next->prev = a;
        };
        
        while (current != NULL) {
            if (current->id == ID && current->idx == index) {
                deallocated = true;
                current->id = -1;
                if (current->prev && current->prev->id == -1) {
                    mergeNodes(current->prev, current);
                    current = current->prev;
                }
                if (current->next && current->next->id == -1) {
                    mergeNodes(current, current->next);
                }
            }
            current = current->next;
        }
        int result;
        if (deallocated) {
            cout << "Freed for thread " << ID << endl;
            print();
            result = 1;
        }
        else {
            cout << "Not successful!" << endl;
            print();
            result = -1;
        }
        mtx.unlock();
        return result;
    }
    
    void print() {
        Node *current = head;
        
        while (current->next != NULL) {
            cout << "[" << current->id << "]" << "[" << current->size << "]" << "[" << current->idx << "]---";
            current = current->next;
        }
        cout << "[" << current->id << "]" << "[" << current->size << "]" << "[" << current->idx << "]" << endl;
    }
};

