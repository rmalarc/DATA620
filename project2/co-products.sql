drop table tiohv if exists;
create temp table tiohv as	
select distinct trade_item_key,
				lgl_entity_key,
				trade_item_hier_l1_key,
							trade_item_hier_l1_desc,
							trade_item_hier_l2_desc,
							trade_item_hier_l5_desc,
							owner_trade_item_desc,
							owner_brand_desc
from trade_item_owner_hierarchy_v  h
where lgl_entity_key in (select distinct lgl_entity_key from touchpoint_v where csdb_chn_nbr = 46)
and trade_item_hier_l5_desc in ('FRESH','GROCERY','SOFTLINES','IN AND OUTDOOR HOME','PETS AND CONSUMABLES');

drop table top100 if exists;
create temp table top100 as 
select * from (
select 
							tp.lgl_entity_key,
--							ord_date_key as date_key,
							csdb_chn_nbr,
							orig_site_id_txt,
							itm.trade_item_cd,
							itm.trade_item_key,
							itm.trade_item_desc,
							trade_item_hier_l1_desc,
							trade_item_hier_l2_desc,
							trade_item_hier_l5_desc,
							owner_trade_item_desc,
							owner_brand_desc,
							sum( purch_qty ) as total_purch_qty,
							sum( purch_amt ) as total_purch_amt,
							avg( purch_amt / purch_qty ) as avg_unit_price,
							count(*) as transactions,
							count( distinct o.ord_event_key ) trips,
							rank()  over ( order by count(*) desc) ranking
							
						from
							ord_trd_itm_cnsmr_fact_ne_v o inner join touchpoint_v tp on
							tp.touchpoint_key = o.ord_touchpoint_key
							and csdb_chn_nbr = 46
							and orig_site_id_txt =
								50
							inner join trade_item_v itm on
							o.trade_item_key = itm.trade_item_key inner join time_v t on
							t.time_key = o.ord_time_key inner join tiohv h on
							h.lgl_entity_key = tp.lgl_entity_key
							and h.trade_item_key = itm.trade_item_key
						where
							o.ord_date_key between 20170609 and 20170610
							and purch_qty > 0
							and purch_amt > 0
							and not(
								trade_item_cd <= 0
								or trade_item_cd between 99000 and 99999
							)
						group by tp.lgl_entity_key,
--							ord_date_key,
							csdb_chn_nbr,
							orig_site_id_txt,
							itm.trade_item_cd,
							itm.trade_item_key,
							itm.trade_item_desc,
							trade_item_hier_l1_desc,
							trade_item_hier_l2_desc,
							trade_item_hier_l5_desc,
							owner_trade_item_desc,
							owner_brand_desc
							) t
							--where ranking <=100
							;

							drop table orders if exists;

drop table orders if exists;
create temp table orders as
select distinct rank()  over ( order by o.ord_event_key) + 10000000 order_id,rank()  over ( order by trade_item_hier_l1_key) product_id,trim(trade_item_hier_l1_desc) product_desc,trim(trade_item_hier_l2_desc) cat_desc
--select distinct o.ord_event_key,
from ord_trd_itm_cnsmr_fact_ne_v o 
inner join tiohv h on  h.trade_item_key = o.trade_item_key
inner join (
		select ord_event_key 
		from ord_trd_itm_cnsmr_fact_ne_v o 
		inner join touchpoint_v tp on
							tp.touchpoint_key = o.ord_touchpoint_key
							and csdb_chn_nbr = 46
							and orig_site_id_txt =
								50
							inner join trade_item_v itm on
							o.trade_item_key = itm.trade_item_key inner join time_v t on
							t.time_key = o.ord_time_key 
							inner join tiohv h on
							h.lgl_entity_key = tp.lgl_entity_key
							and h.trade_item_key = itm.trade_item_key
						where
							o.ord_date_key between 20170609 and 20170610
) t100 on t100.ord_event_key = o.ord_event_key;

select * from orders; 
--where order_id in (
--select order_id from orders group by order_id having  count(*) <25)