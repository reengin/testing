#!/usr/bin/perl




sub main
{
    my ( $jt, $jc0, $jc1 ) = helper_test_preparation();
    
    tc443( jt=>$jt, jc0=>$jc0, jc1=>$jc1);
}

sub tc443
{
    my ( $jt, $jc0, $jc1 ) = jparams qw( jt jc0 jc1 );
    

    # Start your test case here.
    my $tc = Janus_Test->start_testblock(tc=>"TC443");
    
    # 0. precreate systems pool vd presentation
    # 1. start io (any) on this vd
    # 2. set disk_timeout=240
    # 3. pull drive from this vd 
    # 4. verify status pd via show pool 
    # 5. insert disk UNTILL timeout
    # 6. verify status ( allow the rebuild start)
    # 7. if status rebuild pull drive again
    # 8. verify status pd via show pool 
    # 9. insert disk UNTILL timeout
    # 10. sleep 2 min, check host load status 
    # 11. check on type of pool
    
    
    #0 Prepearing pool and vd
    Janus_Test->log_c( "Prepearing create system ( raidset, vd)");
    my @extra_params = ( 'fake_drive', 8 );
    @extra_params = () if ( $jt->is_platform_EMU() );
	my $pool = helper_create_pool( number=>5, use_jts=>1, @extra_params )->hdto_oid();
    my $vd = helper_create_vd( pool=>$pool)->hdto_oid();
    Janus_Test->log_c( "POOL\t$pool\nVD\t$vd");
    
    #1 set disk_timeout
    my $result = $jt->set_pool( dest=>'jts', oidex_or_all=>$pool, disk_timeout=>'240' );
    Janus_Test->log_c( "Set new disk_timeout" . $result->status_name() . "\n");
    
        
    #2 Start IO on pool
    helper_wait_io ( vd=>$vd );
    helper_do_io( operation=>'write', vd=>$vd, crash_on_error=>'1');
    Janus_Test->log_c( "Start helper_do_io");
    
    
    
    # Get pds and choose one
    Janus_Test->log_c( "-----------------------" );
    my @pool_pds = helper_get_physical_disks( pool=>$pool )->hdto_oid();
    my $pool_pd = $pool_pds[rand (@pool_pds)];
    #
    #my $pd_stats = show_drive_status ( $pool_pd );
    #Janus_Test->log_c( "--- test sub pd_state $pd_state");
    #
    # disk state ----------------------------
    my $pd = helper_get_physical_disks( pd=>$pool_pd, fields=>['member_state'] )->hdto_data();
    if ( $pd->{'member_state'} eq 'RAIDSET_MEMBER_STATE_MISSING')
    {
    	Janus_Test->log_c( "Status: MISSING" );
    }
    elsif ($pd->{'member_state'} eq 'RAIDSET_MEMBER_STATE_NORMAL')
    {
        Janus_Test->log_c( "Status: NORMAL" );
    }
    else 
    {
        Janus_Test->log_c( "Status: $pd->{'member_state'}" );
    }
     # end disk state ------------------------
       
  
    #3  pull drive 
    my $result = helper_pull_pd( pd=>$pool_pd )->hdto_oid();
      
    #4 disk state ----------------------------
    my $pd = helper_get_physical_disks( pd=>$pool_pd, fields=>['member_state'] )->hdto_data();
    if ( $pd->{'member_state'} eq 'RAIDSET_MEMBER_STATE_MISSING')
    {
        Janus_Test->log_c( "Status: MISSING" );
    }
    elsif ($pd->{'member_state'} eq 'RAIDSET_MEMBER_STATE_NORMAL')
    {
        Janus_Test->log_c( "Status: NORMAL" );
    }
    else 
    {
        Janus_Test->log_c( "Status: $pd->{'member_state'}" );
    }
    # end disk state ------------------------

    #5 insert drive
    helper_insert_pd( pd=>$pd );
	
    #6 check normal state
    my $result = helper_wait_pool_state( pool=>$pool, expected_state=>'RAIDSET_STATE_NORMAL' );
    Janus_Test->log_c( "Pool state: $result" );    
    
	#7. if status rebuild pull drive again          
    #8. verify status pd via show pool 
    #9. insert disk UNTILL timeout
    #10. sleep 2 min, check host load status 
    
    
    # Cleanup configuration after test
    #my $result = $jt->delete_configuration( dest=>"jts" );
    helper_delete_existing_configuration ();
    #jdie "Clean configuration failed" . $result->status_name() unless ( $result->is_success() );
    

    $tc->end();
}

sub  show_drive_status 
{
	my $pool_pd = shift;
    my $state_pd;
    my @pd = helper_get_physical_disks( pd=>$pool_pd, fields=>['member_state'] )->hdto_data();
    foreach my $enter (@pd)
    {
        foreach my $key ( keys %$enter)
        {
                Janus_Test->log_c( "Status $key\t ${$enter}{$key}");
                $pd_state = "MISSING" if ( ${$enter}{$key} eq "RAIDSET_MEMBER_STATE_MISSING" );
                $pd_state = "NORMAL" if ( ${$enter}{$key} eq "RAIDSET_MEMBER_STATE_NORMAL" );
                last;
        }
    }
    return $pd_state;
}

sub set_pool_disk_timeout 
{
    # set disk_timeout
    my $pool = shift;
    my $result = $jt->set_pool( dest=>'jts', oidex_or_all=>$pool, disk_timeout=>'240' );
    Janus_Test->log_c( "Set new disk_timeout $result->status_name()");

}


