<?php
class Client
{
  public $id;
  public function __construct($resourceId)
  {
    $this->id = $resourceId;
  }
}
